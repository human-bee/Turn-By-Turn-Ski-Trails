import SwiftUI
import CoreLocation

class MapViewModel: ObservableObject {
    @Published var selectedFeature: MapFeature?
    
    let defaultCenter = CLLocationCoordinate2D(latitude: 39.6403, longitude: -106.3742) // Vail, CO
    let defaultZoom = 14.0
    let defaultPitch = 45.0
    let defaultBearing = 0.0
} 