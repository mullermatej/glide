import SwiftUI

struct GroupMembersView: View {
    var groupId: UUID
    @State private var vm = GroupViewModel()

    var body: some View {
        Group {
            if vm.isLoading && vm.members.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = vm.errorMessage {
                ContentUnavailableView("Failed to load members", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if vm.members.isEmpty {
                ContentUnavailableView("No members", systemImage: "person.3", description: Text("Invite someone to get started."))
            } else {
                List(vm.members) { profile in
                    HStack(spacing: 12) {
                        AvatarView(url: profile.avatarUrl, size: 36)
                        VStack(alignment: .leading) {
                            Text(profile.displayName ?? "Unknown")
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Members")
        .task {
            await vm.fetchMembers(for: groupId)
        }
    }
}
