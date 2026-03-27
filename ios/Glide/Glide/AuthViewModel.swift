import Foundation
import Supabase

@MainActor
@Observable
class AuthViewModel {
    var session: Session? = nil
    var isLoading = false
    var errorMessage: String? = nil

    var isLoggedIn: Bool { session != nil }

    init() {
        Task { await loadSession() }
    }

    private func loadSession() async {
        session = try? await supabase.auth.session
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await supabase.auth.signUp(email: email, password: password)
            session = try await supabase.auth.session
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await supabase.auth.signIn(email: email, password: password)
            session = try await supabase.auth.session
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        try? await supabase.auth.signOut()
        session = nil
    }
}
