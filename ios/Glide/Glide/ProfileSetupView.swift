import SwiftUI
import UIKit

struct ProfileSetupView: View {
    var vm: ProfileViewModel

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var selectedAvatar: String = ProfileSetupView.avatarOptions[0]

    static let avatarOptions: [String] = [
        "https://api.dicebear.com/9.x/adventurer-neutral/png?seed=Sadie&size=256",
        "https://api.dicebear.com/9.x/adventurer-neutral/png?seed=Andrea&size=256",
        "https://api.dicebear.com/9.x/adventurer-neutral/png?seed=Adrian&size=256"
    ]

    private var trimmedFirst: String {
        firstName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedLast: String {
        lastName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isValidName(_ value: String) -> Bool {
        guard value.count >= 2, value.count <= 40 else { return false }
        return value.allSatisfy { $0.isLetter || $0 == " " || $0 == "-" || $0 == "'" }
    }

    private var canSubmit: Bool {
        isValidName(trimmedFirst) && isValidName(trimmedLast) && !vm.isLoading
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Text("Tell us about you")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Your name and a picture so friends recognize you.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    VStack(spacing: 12) {
                        nameField(title: "First name", text: $firstName, contentType: .givenName)
                        nameField(title: "Last name", text: $lastName, contentType: .familyName)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pick an avatar")
                            .font(.headline)
                        HStack(spacing: 16) {
                            ForEach(Self.avatarOptions, id: \.self) { url in
                                Button {
                                    selectedAvatar = url
                                } label: {
                                    AvatarView(url: url, size: 72)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(
                                                    selectedAvatar == url ? Color.accentColor : Color.clear,
                                                    lineWidth: 3
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let error = vm.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task {
                            let fullName = "\(trimmedFirst) \(trimmedLast)"
                            await vm.updateProfile(displayName: fullName, avatarUrl: selectedAvatar)
                        }
                    } label: {
                        Group {
                            if vm.isLoading {
                                ProgressView()
                            } else {
                                Text("Continue")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSubmit ? Color.accentColor : Color.gray.opacity(0.4))
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!canSubmit)
                }
                .padding(24)
            }
        }
    }

    @ViewBuilder
    private func nameField(title: String, text: Binding<String>, contentType: UITextContentType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(title, text: text)
                .textContentType(contentType)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            if !text.wrappedValue.isEmpty, !isValidName(text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)) {
                Text("2–40 letters. Spaces, hyphens, and apostrophes allowed.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}
