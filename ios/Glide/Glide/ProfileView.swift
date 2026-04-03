import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = ProfileViewModel()
    @State private var displayName = ""
    @State private var avatarUrl = ""
    @State private var hasLoaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        AvatarView(url: avatarUrl.isEmpty ? nil : avatarUrl, size: 80)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Display Name") {
                    TextField("Enter your name", text: $displayName)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                }

                Section("Avatar URL") {
                    TextField("https://example.com/photo.jpg", text: $avatarUrl)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }

                if let error = vm.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await vm.updateProfile(
                                displayName: displayName,
                                avatarUrl: avatarUrl
                            )
                            if vm.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading)
                }
            }
            .task {
                guard !hasLoaded else { return }
                await vm.fetchProfile()
                if let profile = vm.profile {
                    displayName = profile.displayName ?? ""
                    avatarUrl = profile.avatarUrl ?? ""
                }
                hasLoaded = true
            }
        }
    }
}
