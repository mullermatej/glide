import Foundation
import Supabase

@MainActor
@Observable
class TicketViewModel {
    var tickets: [Ticket] = []
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
