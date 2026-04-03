import SwiftUI

struct GroupDetailView: View {
    var group: TripGroup
    @State private var tripVM: TripViewModel
    @State private var showCreateTrip = false
    @State private var showInvite = false
    @State private var showMembers = false

    init(group: TripGroup) {
        self.group = group
        _tripVM = State(initialValue: TripViewModel(groupId: group.id))
    }

    var body: some View {
        Group {
            if tripVM.isLoading && tripVM.trips.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = tripVM.errorMessage {
                ContentUnavailableView("Failed to load trips", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if tripVM.trips.isEmpty {
                ContentUnavailableView("No trips yet", systemImage: "airplane", description: Text("Add a trip to start planning."))
            } else {
                List {
                    ForEach(tripVM.trips) { trip in
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trip.name)
                                    .fontWeight(.medium)
                                if let destination = trip.destination {
                                    Text(destination)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                if let start = trip.startDate, let end = trip.endDate {
                                    Text("\(start.formatted(date: .abbreviated, time: .omitted)) – \(end.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { offsets in
                        let tripsToDelete = offsets.map { tripVM.trips[$0] }
                        Task {
                            for trip in tripsToDelete {
                                await tripVM.deleteTrip(trip)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(group.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("New Trip") { showCreateTrip = true }
                    Button("Invite Member") { showInvite = true }
                    NavigationLink("Members", destination: GroupMembersView(groupId: group.id))
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showCreateTrip) {
            CreateTripView(vm: tripVM)
        }
        .sheet(isPresented: $showInvite) {
            InviteMemberView(vm: GroupViewModel(), groupId: group.id)
        }
        .task {
            await tripVM.fetchTrips()
        }
    }
}
