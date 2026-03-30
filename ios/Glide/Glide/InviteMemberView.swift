import SwiftUI

struct InviteMemberView: View {
    var vm: GroupViewModel
    var groupId: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var searchResult: Profile? = nil
    @State private var searched = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Find by display name") {
                    HStack {
                        TextField("Display name", text: $displayName)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        Button("Search") {
                            Task {
                                searched = true
                                searchResult = await vm.findProfile(byDisplayName: displayName)
                            }
                        }
                        .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                if searched {
                    if let profile = searchResult {
                        Section("Result") {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(profile.displayName ?? "Unknown")
                                        .fontWeight(.medium)
                                    Text(profile.id.uuidString)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Invite") {
                                    Task {
                                        await vm.inviteMember(to: groupId, userId: profile.id)
                                        if vm.errorMessage == nil { dismiss() }
                                    }
                                }
                                .disabled(vm.isLoading)
                            }
                        }
                    } else {
                        Section {
                            Text("No user found with that display name.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let error = vm.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
