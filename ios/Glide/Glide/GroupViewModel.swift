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
    var members: [Profile] = []
    var isLoading = false
    var errorMessage: String? = nil

    func fetchGroups() async {
        isLoading = true
        errorMessage = nil
        do {
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

    func leaveGroup(_ groupId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let userId = try await supabase.auth.session.user.id
            let removed: [GroupMember] = try await supabase
                .from("group_members")
                .delete()
                .eq("group_id", value: groupId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .select()
                .execute()
                .value
            if removed.isEmpty {
                errorMessage = "Couldn't leave the group. Check database permissions."
            } else {
                groups.removeAll { $0.id == groupId }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteGroup(_ groupId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let removed: [TripGroup] = try await supabase
                .from("groups")
                .delete()
                .eq("id", value: groupId.uuidString)
                .select()
                .execute()
                .value
            if removed.isEmpty {
                errorMessage = "Couldn't delete the group. Check database permissions."
            } else {
                groups.removeAll { $0.id == groupId }
            }
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

    func fetchMembers(for groupId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let memberRows: [GroupMember] = try await supabase
                .from("group_members")
                .select()
                .eq("group_id", value: groupId.uuidString)
                .execute()
                .value
            let userIds = memberRows.map(\.userId)

            if userIds.isEmpty {
                members = []
            } else {
                members = try await supabase
                    .from("profiles")
                    .select()
                    .in("id", values: userIds.map(\.uuidString))
                    .execute()
                    .value
            }
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
