import SwiftUI

struct AuthView: View {
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""

    var auth: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text(isSignUp ? "Create account" : "Welcome back")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }

            if let error = auth.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            Button {
                Task {
                    if isSignUp {
                        await auth.signUp(email: email, password: password)
                    } else {
                        await auth.signIn(email: email, password: password)
                    }
                }
            } label: {
                Group {
                    if auth.isLoading {
                        ProgressView()
                    } else {
                        Text(isSignUp ? "Sign up" : "Sign in")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .cornerRadius(10)
            }
            .disabled(auth.isLoading || email.isEmpty || password.isEmpty)

            Button {
                isSignUp.toggle()
                auth.errorMessage = nil
            } label: {
                Text(isSignUp ? "Already have an account? Sign in" : "Don't have an account? Sign up")
                    .font(.footnote)
            }
        }
        .padding(24)
    }
}
