import SwiftUI

struct CreateTripView: View {
    var vm: TripViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var destination = ""
    @State private var hasDateRange = false
    @State private var startDate = Date()
    @State private var endDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Trip name", text: $name)
                    TextField("Destination (optional)", text: $destination)
                }

                Section {
                    Toggle("Set dates", isOn: $hasDateRange)
                    if hasDateRange {
                        DatePicker("Start", selection: $startDate, displayedComponents: .date)
                        DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
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
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        Task {
                            await vm.createTrip(
                                name: name,
                                destination: destination.isEmpty ? nil : destination,
                                startDate: hasDateRange ? startDate : nil,
                                endDate: hasDateRange ? endDate : nil
                            )
                            if vm.errorMessage == nil { dismiss() }
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading)
                }
            }
        }
    }
}
