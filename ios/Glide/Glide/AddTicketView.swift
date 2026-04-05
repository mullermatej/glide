import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AddTicketView: View {
    var vm: TicketViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fileName = ""
    @State private var category = ""
    @State private var fileData: Data?
    @State private var showFilePicker = false
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?

    private let categories = ["", "boarding_pass", "hotel", "restaurant", "transport", "activity", "other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("File") {
                    if fileData != nil {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(.green)
                            Text(fileName)
                                .lineLimit(1)
                            Spacer()
                            Button("Remove") {
                                fileData = nil
                                fileName = ""
                            }
                            .foregroundStyle(.red)
                            .font(.caption)
                        }
                    } else {
                        Button {
                            showFilePicker = true
                        } label: {
                            Label("Choose File", systemImage: "doc.badge.plus")
                        }
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Choose Photo", systemImage: "photo.badge.plus")
                        }
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        Text("None").tag("")
                        Text("Boarding Pass").tag("boarding_pass")
                        Text("Hotel").tag("hotel")
                        Text("Restaurant").tag("restaurant")
                        Text("Transport").tag("transport")
                        Text("Activity").tag("activity")
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
            .navigationTitle("Add Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Upload") {
                        Task {
                            guard let data = fileData else { return }
                            await vm.uploadTicket(
                                fileName: fileName,
                                fileData: data,
                                category: category.isEmpty ? nil : category
                            )
                            if vm.errorMessage == nil { dismiss() }
                        }
                    }
                    .disabled(fileData == nil || vm.isLoading)
                }
            }
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf, .image, .jpeg, .png]) { result in
                switch result {
                case .success(let url):
                    let gotAccess = url.startAccessingSecurityScopedResource()
                    defer { if gotAccess { url.stopAccessingSecurityScopedResource() } }
                    if let data = try? Data(contentsOf: url) {
                        fileData = data
                        fileName = url.lastPathComponent
                    }
                case .failure(let error):
                    vm.errorMessage = error.localizedDescription
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let newValue, let data = try? await newValue.loadTransferable(type: Data.self) {
                        fileData = data
                        fileName = "photo_\(UUID().uuidString.prefix(8)).jpg"
                    }
                }
            }
        }
    }
}
