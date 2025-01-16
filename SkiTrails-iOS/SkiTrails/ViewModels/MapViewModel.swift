import SwiftUI
import CoreLocation
import SkiTrailsCore
import MapboxMaps

class MapViewModel: ObservableObject {
    @Published var selectedFeature: MapFeature?
    @Published var mapLoaded = false
    @Published var showFeatureDetails = false
    
    var mapView: MapView?
    
    let defaultCenter = CLLocationCoordinate2D(latitude: 39.6403, longitude: -106.3742) // Vail, CO
    let defaultZoom = 14.0
    let defaultPitch = 45.0
    let defaultBearing = 0.0
    
    func handleFeatureSelection(_ feature: MapFeature) {
        selectedFeature = feature
        showFeatureDetails = true
    }
    
    func clearSelection() {
        selectedFeature = nil
        showFeatureDetails = false
    }
    
    func getCameraOptions(for coordinate: CLLocationCoordinate2D? = nil) -> CameraOptions {
        CameraOptions(
            center: coordinate ?? defaultCenter,
            zoom: defaultZoom,
            bearing: defaultBearing,
            pitch: defaultPitch
        )
    }
    
    func handleMapUpdate(_ mapView: MapView) {
        // Handle any map state updates after gesture animations
        // For now, we'll just ensure the map is marked as loaded
        if !mapLoaded {
            mapLoaded = true
        }
    }
} 