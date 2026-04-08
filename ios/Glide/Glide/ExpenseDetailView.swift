import SwiftUI
import MapKit

struct ExpenseDetailView: View {
    var expense: Expense
    var payerName: String

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    Text(String(format: "%.2f %@", expense.amount, expense.currency))
                        .font(.system(size: 36, weight: .bold))
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section {
                LabeledContent("Description", value: expense.description)
                LabeledContent("Paid by", value: payerName)
                if let category = expense.category {
                    LabeledContent("Category", value: category.capitalized)
                }
                LabeledContent("Date", value: expense.createdAt.formatted(date: .abbreviated, time: .shortened))
            }

            if let lat = expense.latitude, let lon = expense.longitude {
                Section {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        latitudinalMeters: 500,
                        longitudinalMeters: 500
                    ))) {
                        Marker(expense.description, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                    }
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

                    if let name = expense.locationName {
                        Button {
                            openInMaps(latitude: lat, longitude: lon)
                        } label: {
                            HStack {
                                Text(name)
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Location")
                }
            }
        }
        .navigationTitle("Expense")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openInMaps(latitude: Double, longitude: Double) {
        let query = expense.description.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "maps://?ll=\(latitude),\(longitude)&q=\(query)&z=15") else { return }
        UIApplication.shared.open(url)
    }
}
