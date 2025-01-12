import SwiftUI
import MapboxMaps
import CoreLocation
import SkiTrailsCore
import UIKit

struct MapboxMapView: UIViewRepresentable {
    typealias UIViewType = UIView
    
    let initialCoordinates: CLLocationCoordinate2D
    let initialZoom: Double
    let initialPitch: Double
    let initialBearing: Double
    @Binding var selectedFeature: MapFeature?
    
    func makeUIView(context: Context) -> UIView {
        let resourceOptions = ResourceOptions(accessToken: EnvConfig.mapboxAccessToken)
        let cameraOptions = CameraOptions(
            center: initialCoordinates,
            zoom: initialZoom,
            bearing: initialBearing,
            pitch: initialPitch
        )
        let initOptions = MapInitOptions(resourceOptions: resourceOptions,
                                       cameraOptions: cameraOptions)
        
        let containerView = UIView()
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let mapView = MapboxMaps.MapView(frame: containerView.bounds, mapInitOptions: initOptions)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(mapView)
        
        // Store mapView in coordinator for later access
        context.coordinator.mapView = mapView
        
        // Observe style loaded event
        mapView.mapboxMap.onNext(event: .styleLoaded) { _ in
            // Map style finished loading
            // Add any style-dependent layers or sources here
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let mapView = context.coordinator.mapView else { return }
        
        // Update selected feature if needed
        if let feature = selectedFeature {
            let coords = feature.coordinates
            let coordinate = CLLocationCoordinate2D(
                latitude: coords.latitude,
                longitude: coords.longitude
            )
            let camera = CameraOptions(center: coordinate, zoom: 15.0)
            mapView.camera.ease(to: camera, duration: 0.5)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: MapboxMapView
        var mapView: MapboxMaps.MapView?
        
        init(_ parent: MapboxMapView) {
            self.parent = parent
        }
    }
} 