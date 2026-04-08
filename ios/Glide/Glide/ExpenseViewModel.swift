import Foundation
import Supabase

@MainActor
@Observable
class ExpenseViewModel {
    var expenses: [Expense] = []
    var payerNames: [UUID: String] = [:]
    var isLoading = false
    var errorMessage: String? = nil

    let tripId: UUID

    init(tripId: UUID) {
        self.tripId = tripId
    }

    func fetchExpenses() async {
        isLoading = true
        errorMessage = nil
        do {
            expenses = try await supabase
                .from("expenses")
                .select()
                .eq("trip_id", value: tripId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            let payerIds = Set(expenses.map(\.paidBy))
            if !payerIds.isEmpty {
                let profiles: [Profile] = try await supabase
                    .from("profiles")
                    .select()
                    .in("id", values: payerIds.map(\.uuidString))
                    .execute()
                    .value
                for profile in profiles {
                    payerNames[profile.id] = profile.displayName ?? "Unknown"
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addExpense(amount: Double, currency: String, description: String, category: String?, latitude: Double?, longitude: Double?, locationName: String?) async {
        guard let userId = try? await supabase.auth.session.user.id else {
            errorMessage = "Not logged in"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            var payload: [String: String] = [
                "trip_id": tripId.uuidString,
                "paid_by": userId.uuidString,
                "amount": String(amount),
                "currency": currency,
                "description": description
            ]
            if let category, !category.isEmpty {
                payload["category"] = category
            }
            if let latitude {
                payload["latitude"] = String(latitude)
            }
            if let longitude {
                payload["longitude"] = String(longitude)
            }
            if let locationName, !locationName.isEmpty {
                payload["location_name"] = locationName
            }

            let newExpense: Expense = try await supabase
                .from("expenses")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

            if payerNames[userId] == nil {
                let profiles: [Profile] = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: userId.uuidString)
                    .limit(1)
                    .execute()
                    .value
                payerNames[userId] = profiles.first?.displayName ?? "Unknown"
            }

            expenses.insert(newExpense, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteExpense(_ expense: Expense) async {
        errorMessage = nil
        do {
            try await supabase
                .from("expenses")
                .delete()
                .eq("id", value: expense.id.uuidString)
                .execute()

            expenses.removeAll { $0.id == expense.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var total: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
}
