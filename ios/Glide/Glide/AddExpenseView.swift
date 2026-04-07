import SwiftUI

struct AddExpenseView: View {
    var vm: ExpenseViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var amount = ""
    @State private var currency = "EUR"
    @State private var description = ""
    @State private var category = ""

    private let currencies = ["EUR", "USD", "GBP", "HRK", "CHF", "JPY", "AUD", "CAD"]
    private let categories = ["", "food", "transport", "accommodation", "activities", "shopping", "other"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Description", text: $description)
                    HStack {
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                        Picker("", selection: $currency) {
                            ForEach(currencies, id: \.self) { Text($0) }
                        }
                        .labelsHidden()
                        .frame(width: 80)
                    }
                }

                Section {
                    Picker("Category", selection: $category) {
                        Text("None").tag("")
                        Text("Food").tag("food")
                        Text("Transport").tag("transport")
                        Text("Accommodation").tag("accommodation")
                        Text("Activities").tag("activities")
                        Text("Shopping").tag("shopping")
                        Text("Other").tag("other")
                    }
                }

                if let error = vm.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        Task {
                            guard let parsed = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
                                vm.errorMessage = "Enter a valid amount"
                                return
                            }
                            await vm.addExpense(
                                amount: parsed,
                                currency: currency,
                                description: description,
                                category: category.isEmpty ? nil : category
                            )
                            if vm.errorMessage == nil { dismiss() }
                        }
                    }
                    .disabled(description.trimmingCharacters(in: .whitespaces).isEmpty || amount.isEmpty || vm.isLoading)
                }
            }
        }
    }
}
