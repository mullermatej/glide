import SwiftUI

struct GroupListView: View {
    var auth: AuthViewModel
    @State private var vm = GroupViewModel()
    @State private var showCreateSheet = false

    var body: some View {
    
        NavigationStack {
            Group {
                if vm.isLoading && vm.groups.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.groups.isEmpty {
                    ContentUnavailableView("No groups yet", systemImage: "person.3", description: Text("Create a group to start planning trips."))
                } else {
                    List(vm.groups) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            Text(group.name)
                        }
                    }
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sign out") {
                        Task { await auth.signOut() }
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateGroupView(vm: vm)
            }
            .task {
                await vm.fetchGroups()
            }
        }
    }
}
