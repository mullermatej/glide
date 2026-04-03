import Foundation
import Supabase

@MainActor
@Observable
class TripViewModel {
    var trips: [Trip] = []
    var isLoading = false
    var errorMessage: String? = nil

    let groupId: UUID

    init(groupId: UUID) {
        self.groupId = groupId
    }

    // MARK: - Fetch

    func fetchTrips() async {
        isLoading = true
        errorMessage = nil
        do {
            trips = try await supabase
                .from("trips")
                .select()
                .eq("group_id", value: groupId.uuidString)
                .order("created_at")
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Create

    func createTrip(name: String, destination: String?, startDate: Date?, endDate: Date?) async {
        guard let userId = try? await supabase.auth.session.user.id else {
            errorMessage = "Not logged in"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            var payload: [String: String] = [
                "group_id": groupId.uuidString,
                "name": name,
                "created_by": userId.uuidString
            ]
            if let destination, !destination.isEmpty {
                payload["destination"] = destination
            }
            if let startDate {
                payload["start_date"] = ISO8601DateFormatter.dateOnly.string(from: startDate)
            }
            if let endDate {
                payload["end_date"] = ISO8601DateFormatter.dateOnly.string(from: endDate)
            }

            let newTrip: Trip = try await supabase
                .from("trips")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

            trips.append(newTrip)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Delete

    func deleteTrip(_ trip: Trip) async {
        errorMessage = nil
        do {
            try await supabase
                .from("trips")
                .delete()
                .eq("id", value: trip.id.uuidString)
                .execute()

            trips.removeAll { $0.id == trip.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Helpers

private extension ISO8601DateFormatter {
    static let dateOnly: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return f
    }()
}
