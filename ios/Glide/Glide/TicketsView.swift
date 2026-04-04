import SwiftUI

struct TicketsView: View {
    var tripId: UUID
    @State private var ticketVM: TicketViewModel

    init(tripId: UUID) {
        self.tripId = tripId
        _ticketVM = State(initialValue: TicketViewModel(tripId: tripId))
    }

    var body: some View {
        Group {
            if ticketVM.isLoading && ticketVM.tickets.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = ticketVM.errorMessage {
                ContentUnavailableView("Failed to load tickets", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if ticketVM.tickets.isEmpty {
                ContentUnavailableView("No tickets yet", systemImage: "doc.text", description: Text("Upload boarding passes, reservations, and more."))
            } else {
                List {
                    ForEach(ticketVM.tickets) { ticket in
                        HStack(spacing: 12) {
                            Image(systemName: iconForCategory(ticket.category))
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ticket.fileName)
                                    .fontWeight(.medium)
                                if let category = ticket.category {
                                    Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        let toDelete = offsets.map { ticketVM.tickets[$0] }
                        Task {
                            for ticket in toDelete {
                                await ticketVM.deleteTicket(ticket)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Tickets")
        .task {
            await ticketVM.fetchTickets()
        }
    }

    private func iconForCategory(_ category: String?) -> String {
        switch category {
        case "boarding_pass": return "airplane.circle"
        case "hotel": return "bed.double"
        case "restaurant": return "fork.knife"
        case "transport": return "car"
        case "activity": return "ticket"
        default: return "doc.text"
        }
    }
}
