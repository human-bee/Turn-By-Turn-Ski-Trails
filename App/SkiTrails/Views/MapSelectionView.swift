import SwiftUI
import MapKit
import CoreLocation

struct MapSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var coordinate: CLLocationCoordinate2D?
    let title: String
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, interactionModes: .all) {
                if let coordinate = coordinate {
                    Marker("Selected Location", coordinate: coordinate)
                }
            }
            .onTapGesture { location in
                coordinate = region.center
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(coordinate == nil)
                }
            }
        }
    }
}

#Preview {
    MapSelectionView(
        coordinate: .constant(nil),
        title: "Select Location"
    )
} 