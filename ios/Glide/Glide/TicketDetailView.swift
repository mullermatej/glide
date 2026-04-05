import SwiftUI
import PDFKit

struct TicketDetailView: View {
    var ticket: Ticket
    var vm: TicketViewModel
    @State private var signedURL: URL?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let url = signedURL {
                if ticket.fileName.lowercased().hasSuffix(".pdf") {
                    PDFViewer(url: url)
                } else {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            ContentUnavailableView("Failed to load image", systemImage: "photo.badge.exclamationmark")
                        default:
                            ProgressView()
                        }
                    }
                }
            } else {
                ContentUnavailableView("File unavailable", systemImage: "doc.questionmark")
            }
        }
        .navigationTitle(ticket.fileName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            signedURL = await vm.signedURL(for: ticket)
            isLoading = false
        }
    }
}

struct PDFViewer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document == nil {
            Task {
                if let data = try? Data(contentsOf: url) {
                    await MainActor.run {
                        pdfView.document = PDFDocument(data: data)
                    }
                }
            }
        }
    }
}
