import Foundation
import Supabase

@MainActor
@Observable
class BrainstormViewModel {
    var ideas: [BrainstormIdea] = []
    var creatorNames: [UUID: String] = [:]
    var isLoading = false
    var errorMessage: String? = nil

    let tripId: UUID

    init(tripId: UUID) {
        self.tripId = tripId
    }

    func fetchIdeas() async {
        isLoading = true
        errorMessage = nil
        do {
            ideas = try await supabase
                .from("brainstorm_ideas")
                .select()
                .eq("trip_id", value: tripId.uuidString)
                .order("created_at")
                .execute()
                .value

            let creatorIds = Set(ideas.compactMap(\.createdBy))
            if !creatorIds.isEmpty {
                let profiles: [Profile] = try await supabase
                    .from("profiles")
                    .select()
                    .in("id", values: creatorIds.map(\.uuidString))
                    .execute()
                    .value
                for profile in profiles {
                    creatorNames[profile.id] = profile.displayName ?? "Unknown"
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createIdea(text: String, x: Double, y: Double, color: String = "yellow") async {
        guard let userId = try? await supabase.auth.session.user.id else {
            errorMessage = "Not logged in"
            return
        }
        errorMessage = nil
        do {
            let payload: [String: String] = [
                "trip_id": tripId.uuidString,
                "created_by": userId.uuidString,
                "text": text,
                "x_pos": String(x),
                "y_pos": String(y),
                "color": color
            ]

            let newIdea: BrainstormIdea = try await supabase
                .from("brainstorm_ideas")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

            if creatorNames[userId] == nil {
                let profiles: [Profile] = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: userId.uuidString)
                    .limit(1)
                    .execute()
                    .value
                creatorNames[userId] = profiles.first?.displayName ?? "Unknown"
            }

            ideas.append(newIdea)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveIdea(_ idea: BrainstormIdea, to x: Double, y: Double) async {
        guard let index = ideas.firstIndex(where: { $0.id == idea.id }) else { return }
        ideas[index].xPos = x
        ideas[index].yPos = y

        do {
            try await supabase
                .from("brainstorm_ideas")
                .update(["x_pos": String(x), "y_pos": String(y)])
                .eq("id", value: idea.id.uuidString)
                .execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteIdea(_ idea: BrainstormIdea) async {
        errorMessage = nil
        do {
            try await supabase
                .from("brainstorm_ideas")
                .delete()
                .eq("id", value: idea.id.uuidString)
                .execute()

            ideas.removeAll { $0.id == idea.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
