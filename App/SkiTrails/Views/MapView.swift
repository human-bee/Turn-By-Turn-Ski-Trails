import SwiftUI
import MapboxMaps
import CoreLocation

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    
    // Heavenly Mountain Resort coordinates
    private let heavenlyCoordinates = CLLocationCoordinate2D(
        latitude: 38.9353,
        longitude: -119.9400
    )
    
    var body: some View {
        MapboxMapView(viewModel: viewModel)
            .onAppear {
                viewModel.setCamera(
                    center: heavenlyCoordinates,
                    zoom: 13,
                    bearing: 0,
                    pitch: 60
                )
            }
            .navigationTitle("Resort Map")
            .edgesIgnoringSafeArea(.all)
    }
} 