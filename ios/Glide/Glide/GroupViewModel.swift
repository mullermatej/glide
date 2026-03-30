import Foundation
import Supabase

private struct NewGroup: Encodable {
    let id: UUID
    let name: String
    let createdBy: UUID
    enum CodingKeys: String, CodingKey {
        case id, name
        case createdBy = "created_by"
    }
}

private struct NewGroupMember: Encodable {
    let groupId: UUID
    let userId: UUID
    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case userId = "user_id"
    }
}

@MainActor
@Observable
class GroupViewModel {
    var groups: [TripGroup] = []
    var isLoading = false
    var errorMessage: String? = nil

    func fetchGroups() async {
        isLoading = true
        errorMessage = nil
        do {
            // Only fetch groups where the current user is a member
            let userId = try await supabase.auth.session.user.id
            let memberRows: [GroupMember] = try await supabase
                .from("group_members")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            let groupIds = memberRows.map(\.groupId)

            if groupIds.isEmpty {
                groups = []
            } else {
                groups = try await supabase
                    .from("groups")
                    .select()
                    .in("id", values: groupIds.map(\.uuidString))
                    .execute()
                    .value
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createGroup(name: String) async {
        guard let userId = try? await supabase.auth.session.user.id else {
            errorMessage = "Not logged in"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            // Generate ID client-side so we can insert the member row
            // without needing to read back the group first (avoids RLS
            // select-policy blocking the read before membership exists).
            let groupId = UUID()

            try await supabase
                .from("groups")
                .insert(NewGroup(id: groupId, name: name, createdBy: userId))
                .execute()

            try await supabase
                .from("group_members")
                .insert(NewGroupMember(groupId: groupId, userId: userId))
                .execute()

            await fetchGroups()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func inviteMember(to groupId: UUID, userId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            try await supabase
                .from("group_members")
                .insert(NewGroupMember(groupId: groupId, userId: userId))
                .execute()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func findProfile(byDisplayName name: String) async -> Profile? {
        do {
            let profiles: [Profile] = try await supabase
                .from("profiles")
                .select()
                .eq("display_name", value: name)
                .limit(1)
                .execute()
                .value
            return profiles.first
        } catch {
            return nil
        }
    }
}
