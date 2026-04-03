import SwiftUI

struct CreateEventView: View {
    var vm: EventViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var hasSchedule = false
    @State private var scheduledAt = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Event title", text: $title)
                    TextField("Description (optional)", text: $description)
                }

                Section {
                    Toggle("Set date & time", isOn: $hasSchedule)
                    if hasSchedule {
                        DatePicker("When", selection: $scheduledAt)
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
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        Task {
                            await vm.createEvent(
                                title: title,
                                description: description.isEmpty ? nil : description,
                                scheduledAt: hasSchedule ? scheduledAt : nil
                            )
                            if vm.errorMessage == nil { dismiss() }
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading)
                }
            }
        }
    }
}
