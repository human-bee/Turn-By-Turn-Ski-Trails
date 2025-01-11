import SwiftUI
import MapboxMaps
import CoreLocation

struct MapboxMapView: UIViewRepresentable {
    let initialCoordinates: CLLocationCoordinate2D
    let initialZoom: Double
    let initialPitch: Double
    let initialBearing: Double
    @Binding var selectedFeature: MapFeature?
    
    func makeUIView(context: Context) -> MapView {
        let options = MapInitOptions(
            resourceOptions: ResourceOptions(accessToken: EnvConfig.mapboxAccessToken),
            cameraOptions: CameraOptions(
                center: initialCoordinates,
                zoom: initialZoom,
                bearing: initialBearing,
                pitch: initialPitch
            )
        )
        let mapView = MapView(frame: .zero, mapInitOptions: options)
        mapView.mapboxMap.onNext(.mapLoaded) { _ in
            // Map is loaded and ready
        }
        return mapView
    }
    
    func updateUIView(_ mapView: MapView, context: Context) {
        // Update view if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: MapboxMapView
        
        init(_ parent: MapboxMapView) {
            self.parent = parent
        }
    }
} 