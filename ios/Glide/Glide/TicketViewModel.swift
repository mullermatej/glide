import Foundation
import Supabase

@MainActor
@Observable
class TicketViewModel {
    var tickets: [Ticket] = []
    var thumbnailURLs: [UUID: URL] = [:]
    var isLoading = false
    var errorMessage: String? = nil

    let tripId: UUID

    init(tripId: UUID) {
        self.tripId = tripId
    }

    func fetchTickets() async {
        isLoading = true
        errorMessage = nil
        do {
            tickets = try await supabase
                .from("tickets")
                .select()
                .eq("trip_id", value: tripId.uuidString)
                .order("created_at")
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        await fetchThumbnailURLs()
    }

    func fetchThumbnailURLs() async {
        let imageTickets = tickets.filter { Self.isImage($0.fileName) && $0.fileUrl != nil }
        for ticket in imageTickets where thumbnailURLs[ticket.id] == nil {
            if let url = await signedURL(for: ticket) {
                thumbnailURLs[ticket.id] = url
            }
        }
    }

    static func isImage(_ fileName: String) -> Bool {
        let ext = fileName.lowercased()
        return ext.hasSuffix(".jpg") || ext.hasSuffix(".jpeg") || ext.hasSuffix(".png") || ext.hasSuffix(".heic") || ext.hasSuffix(".webp")
    }

    func uploadTicket(fileName: String, fileData: Data, category: String?) async {
        guard let userId = try? await supabase.auth.session.user.id else {
            errorMessage = "Not logged in"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let path = "\(tripId.uuidString)/\(UUID().uuidString)_\(fileName)"

            try await supabase.storage
                .from("tickets")
                .upload(path, data: fileData)

            var payload: [String: String] = [
                "trip_id": tripId.uuidString,
                "uploaded_by": userId.uuidString,
                "file_name": fileName,
                "file_url": path
            ]
            if let category, !category.isEmpty {
                payload["category"] = category
            }

            let newTicket: Ticket = try await supabase
                .from("tickets")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

            tickets.append(newTicket)
            if Self.isImage(fileName), let url = await signedURL(for: newTicket) {
                thumbnailURLs[newTicket.id] = url
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signedURL(for ticket: Ticket) async -> URL? {
        guard let path = ticket.fileUrl else { return nil }
        do {
            return try await supabase.storage
                .from("tickets")
                .createSignedURL(path: path, expiresIn: 3600)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func deleteTicket(_ ticket: Ticket) async {
        errorMessage = nil
        do {
            try await supabase
                .from("tickets")
                .delete()
                .eq("id", value: ticket.id.uuidString)
                .execute()

            tickets.removeAll { $0.id == ticket.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
