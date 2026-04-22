import SwiftUI
import Supabase

struct GroupDetailView: View {
    var group: TripGroup
    var groupVM: GroupViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var tripVM: TripViewModel
    @State private var showCreateTrip = false
    @State private var showInvite = false
    @State private var showMembers = false
    @State private var showLeaveConfirm = false
    @State private var showOwnerDeleteConfirm = false
    @State private var currentUserId: UUID?

    init(group: TripGroup, groupVM: GroupViewModel) {
        self.group = group
        self.groupVM = groupVM
        _tripVM = State(initialValue: TripViewModel(groupId: group.id))
    }

    private var isOwner: Bool {
        guard let currentUserId else { return false }
        return group.createdBy == currentUserId
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
                    Button("Leave Group", role: .destructive) {
                        if isOwner {
                            showOwnerDeleteConfirm = true
                        } else {
                            showLeaveConfirm = true
                        }
                    }
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
        .alert("Leave \(group.name)?", isPresented: $showLeaveConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                Task {
                    await groupVM.leaveGroup(group.id)
                    if groupVM.errorMessage == nil { dismiss() }
                }
            }
        } message: {
            Text("You won't see this group anymore, and other members won't see you.")
        }
        .alert("Delete \(group.name)?", isPresented: $showOwnerDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Group", role: .destructive) {
                Task {
                    await groupVM.deleteGroup(group.id)
                    if groupVM.errorMessage == nil { dismiss() }
                }
            }
        } message: {
            Text("You're the group owner. Leaving will delete the group and all its trips, tickets, expenses, and brainstorm ideas. Every member will lose access.")
        }
        .task {
            currentUserId = try? await supabase.auth.session.user.id
            await tripVM.fetchTrips()
        }
    }
}
