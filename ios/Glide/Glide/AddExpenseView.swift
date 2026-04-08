import SwiftUI
import CoreLocation

struct AddExpenseView: View {
    var vm: ExpenseViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var amount = ""
    @State private var currency = "EUR"
    @State private var description = ""
    @State private var category = ""
    @State private var locationManager = LocationManager()

    private let currencies = ["EUR", "USD", "GBP", "HRK", "CHF", "JPY", "AUD", "CAD"]

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

                Section("Location") {
                    switch locationManager.authorizationStatus {
                    case .notDetermined:
                        Button("Enable Location") {
                            locationManager.requestPermission()
                        }
                    case .denied, .restricted:
                        Label("Location access denied", systemImage: "location.slash")
                            .foregroundStyle(.secondary)
                    default:
                        if locationManager.isResolving {
                            HStack {
                                ProgressView()
                                Text("Getting location...")
                                    .foregroundStyle(.secondary)
                            }
                        } else if let name = locationManager.locationName {
                            Label(name, systemImage: "location.fill")
                        } else if locationManager.currentLocation != nil {
                            Label("Location found", systemImage: "location.fill")
                        } else {
                            HStack {
                                ProgressView()
                                Text("Waiting for location...")
                                    .foregroundStyle(.secondary)
                            }
                        }
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
                                category: category.isEmpty ? nil : category,
                                latitude: locationManager.currentLocation?.coordinate.latitude,
                                longitude: locationManager.currentLocation?.coordinate.longitude,
                                locationName: locationManager.locationName
                            )
                            if vm.errorMessage == nil { dismiss() }
                        }
                    }
                    .disabled(description.trimmingCharacters(in: .whitespaces).isEmpty || amount.isEmpty || vm.isLoading)
                }
            }
            .onAppear {
                if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                    locationManager.requestLocation()
                }
            }
        }
    }
}
