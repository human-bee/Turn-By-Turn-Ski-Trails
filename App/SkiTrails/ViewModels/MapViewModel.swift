import SwiftUI
import MapboxMaps
import CoreLocation

class MapViewModel: ObservableObject {
    @Published var mapCamera = MapCamera(
        center: CLLocationCoordinate2D(latitude: 38.9353, longitude: -119.9400),
        zoom: 13,
        bearing: 0,
        pitch: 60
    )
    
    func setCamera(center: CLLocationCoordinate2D, zoom: Double, bearing: Double, pitch: Double) {
        mapCamera = MapCamera(
            center: center,
            zoom: zoom,
            bearing: bearing,
            pitch: pitch
        )
    }
}

struct MapCamera {
    var center: CLLocationCoordinate2D
    var zoom: Double
    var bearing: Double
    var pitch: Double
} 