import Foundation
import Supabase

@MainActor
@Observable
class EventViewModel {
    var events: [Event] = []
    var isLoading = false
    var errorMessage: String? = nil

    let tripId: UUID

    init(tripId: UUID) {
        self.tripId = tripId
    }

    func fetchEvents() async {
        isLoading = true
        errorMessage = nil
        do {
            events = try await supabase
                .from("events")
                .select()
                .eq("trip_id", value: tripId.uuidString)
                .order("scheduled_at", ascending: true)
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createEvent(title: String, description: String?, scheduledAt: Date?) async {
        guard let userId = try? await supabase.auth.session.user.id else {
            errorMessage = "Not logged in"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            var payload: [String: String] = [
                "trip_id": tripId.uuidString,
                "title": title,
                "created_by": userId.uuidString
            ]
            if let description, !description.isEmpty {
                payload["description"] = description
            }
            if let scheduledAt {
                payload["scheduled_at"] = ISO8601DateFormatter().string(from: scheduledAt)
            }

            let newEvent: Event = try await supabase
                .from("events")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

            events.append(newEvent)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteEvent(_ event: Event) async {
        errorMessage = nil
        do {
            try await supabase
                .from("events")
                .delete()
                .eq("id", value: event.id.uuidString)
                .execute()

            events.removeAll { $0.id == event.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
