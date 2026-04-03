import SwiftUI

struct TripDetailView: View {
    var trip: Trip
    @State private var eventVM: EventViewModel
    @State private var showCreateEvent = false

    init(trip: Trip) {
        self.trip = trip
        _eventVM = State(initialValue: EventViewModel(tripId: trip.id))
    }

    var body: some View {
        Group {
            if eventVM.isLoading && eventVM.events.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    tripInfoSection
                    eventsSection
                }
            }
        }
        .navigationTitle(trip.name)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(
                    item: URL(string: "glide://invite/\(trip.groupId.uuidString)")!,
                    subject: Text(trip.name),
                    message: Text("Join my trip \"\(trip.name)\" on Glide!")
                ) {
                    Image(systemName: "square.and.arrow.up")
                }
                Button {
                    showCreateEvent = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateEvent) {
            CreateEventView(vm: eventVM)
        }
        .task {
            await eventVM.fetchEvents()
        }
    }

    private var tripInfoSection: some View {
        Section {
            if let destination = trip.destination {
                LabeledContent("Destination", value: destination)
            }
            if let start = trip.startDate, let end = trip.endDate {
                LabeledContent("Dates") {
                    Text("\(start.formatted(date: .abbreviated, time: .omitted)) – \(end.formatted(date: .abbreviated, time: .omitted))")
                }
            }
        }
    }

    private var eventsSection: some View {
        Section {
            if eventVM.events.isEmpty {
                Text("No events yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(eventVM.events) { event in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .fontWeight(.medium)
                        if let description = event.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let scheduledAt = event.scheduledAt {
                            Text(scheduledAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { offsets in
                    let eventsToDelete = offsets.map { eventVM.events[$0] }
                    Task {
                        for event in eventsToDelete {
                            await eventVM.deleteEvent(event)
                        }
                    }
                }
            }
        } header: {
            Text("Events")
        }
    }
}
