import SwiftUI

struct ExpensesView: View {
    var tripId: UUID
    @State private var vm: ExpenseViewModel
    @State private var showAddExpense = false

    init(tripId: UUID) {
        self.tripId = tripId
        _vm = State(initialValue: ExpenseViewModel(tripId: tripId))
    }

    var body: some View {
        Group {
            if vm.isLoading && vm.expenses.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = vm.errorMessage {
                ContentUnavailableView("Failed to load expenses", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if vm.expenses.isEmpty {
                ContentUnavailableView("No expenses yet", systemImage: "creditcard", description: Text("Track what everyone spends."))
            } else {
                List {
                    Section {
                        HStack {
                            Text("Total")
                                .fontWeight(.medium)
                            Spacer()
                            Text(String(format: "%.2f %@", vm.total, vm.expenses.first?.currency ?? "EUR"))
                                .fontWeight(.semibold)
                        }
                    }

                    Section {
                        ForEach(vm.expenses) { expense in
                            NavigationLink(destination: ExpenseDetailView(
                                expense: expense,
                                payerName: vm.payerNames[expense.paidBy] ?? "Unknown"
                            )) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(expense.description)
                                            .fontWeight(.medium)
                                        Text(vm.payerNames[expense.paidBy] ?? "Unknown")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        if let category = expense.category {
                                            Text(category.capitalized)
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                    Spacer()
                                    Text(String(format: "%.2f %@", expense.amount, expense.currency))
                                        .fontWeight(.medium)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { offsets in
                            let toDelete = offsets.map { vm.expenses[$0] }
                            Task {
                                for expense in toDelete {
                                    await vm.deleteExpense(expense)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Expenses")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddExpense = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView(vm: vm)
        }
        .task {
            await vm.fetchExpenses()
        }
    }
}
