import Foundation
import Supabase

private struct ProfileUpdate: Encodable {
    let displayName: String
    let avatarUrl: String?
    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

@MainActor
@Observable
class ProfileViewModel {
    var profile: Profile?
    var isLoading = false
    var errorMessage: String? = nil

    func fetchProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            let userId = try await supabase.auth.session.user.id
            let profiles: [Profile] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value
            profile = profiles.first
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateProfile(displayName: String, avatarUrl: String?) async {
        guard let userId = try? await supabase.auth.session.user.id else {
            errorMessage = "Not logged in"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let updated: Profile = try await supabase
                .from("profiles")
                .update(ProfileUpdate(
                    displayName: displayName,
                    avatarUrl: avatarUrl?.isEmpty == true ? nil : avatarUrl
                ))
                .eq("id", value: userId.uuidString)
                .select()
                .single()
                .execute()
                .value
            profile = updated
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
