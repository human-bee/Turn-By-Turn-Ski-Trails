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
    
    private var annotations: [IdentifiableCoordinate] {
        if let coordinate = coordinate {
            return [IdentifiableCoordinate(coordinate: coordinate)]
        }
        return []
    }
    
    var body: some View {
        NavigationStack {
            Map {
                ForEach(annotations) { annotation in
                    Marker("Selected Location", coordinate: annotation.coordinate)
                }
                UserAnnotation()
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .onTapGesture { _ in
                withAnimation {
                    coordinate = region.center
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                    .disabled(coordinate == nil)
                }
            }
        }
    }
}

private struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    MapSelectionView(
        coordinate: .constant(nil),
        title: "Select Location"
    )
} 