import SwiftUI
import MapboxMaps

struct MapView: UIViewRepresentable {
    @ObservedObject var viewModel: ContentViewModel
    
    func makeUIView(context: Context) -> MapboxMaps.MapView {
        let options = MapInitOptions(resourceOptions: ResourceOptionsManager.default.resourceOptions)
        let mapView = MapboxMaps.MapView(frame: .zero, mapInitOptions: options)
        
        // Set initial camera position
        mapView.mapboxMap.setCamera(
            to: CameraOptions(
                center: viewModel.mapCamera.center,
                zoom: viewModel.mapCamera.zoom,
                bearing: viewModel.mapCamera.bearing,
                pitch: viewModel.mapCamera.pitch
            )
        )
        
        // Load terrain style
        mapView.mapboxMap.loadStyleURI(.outdoors) { result in
            switch result {
            case .success(let style):
                // Add terrain if available
                if let source = style.terrain?.source {
                    try? style.setTerrainProperties(TerrainProperties(exaggeration: 1.5, source: source))
                }
            case .failure(let error):
                print("Failed to load style: \(error)")
            }
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MapboxMaps.MapView, context: Context) {
        // Update camera if it changed
        mapView.camera.ease(
            to: CameraOptions(
                center: viewModel.mapCamera.center,
                zoom: viewModel.mapCamera.zoom,
                bearing: viewModel.mapCamera.bearing,
                pitch: viewModel.mapCamera.pitch
            ),
            duration: 0.5
        )
        
        // TODO: Update annotations for lifts and runs
        // This will be implemented in the next iteration
    }
} 