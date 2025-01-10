import SwiftUI
import MapboxMaps
import CoreLocation

struct MapboxMapView: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel
    
    func makeUIView(context: Context) -> MapboxMaps.MapView {
        let accessToken: String
        do {
            accessToken = try MapConfig.getMapboxAccessToken()
        } catch {
            fatalError("Mapbox access token not configured: \(error.localizedDescription)")
        }
        
        let options = MapInitOptions(
            resourceOptions: ResourceOptions(accessToken: accessToken),
            cameraOptions: CameraOptions(
                center: viewModel.mapCamera.center,
                zoom: viewModel.mapCamera.zoom,
                bearing: viewModel.mapCamera.bearing,
                pitch: viewModel.mapCamera.pitch
            ),
            styleURI: .outdoors
        )
        
        let mapView = MapboxMaps.MapView(frame: .zero, mapInitOptions: options)
        
        // Configure gestures
        mapView.gestures.options.rotateEnabled = true
        mapView.gestures.options.pinchZoomEnabled = true
        mapView.gestures.options.pitchEnabled = true
        mapView.gestures.options.doubleTapToZoomInEnabled = true
        mapView.gestures.options.doubleTouchToZoomOutEnabled = true
        mapView.gestures.options.quickZoomEnabled = true
        
        // Set zoom constraints
        mapView.mapboxMap.setCamera(to: CameraOptions(
            minZoom: 12,
            maxZoom: 18,
            minPitch: 0,
            maxPitch: 85
        ))
        
        // Configure the map style after loading
        mapView.mapboxMap.onStyleLoaded.observe { _ in
            do {
                try self.configureMapStyle(mapView)
            } catch {
                print("Failed to configure map style: \(error)")
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
    }
    
    private func configureMapStyle(_ mapView: MapboxMaps.MapView) throws {
        let style = mapView.mapboxMap.style
        
        // Add terrain source and configure 3D terrain
        let terrainSource = TerrainSource(identifier: "mapbox-dem")
        try style.addSource(terrainSource)
        
        let terrain = Terrain(sourceId: "mapbox-dem")
        try style.setTerrain(terrain)
        
        let terrainParams = TerrainParams(exaggeration: 1.5)
        try style.setTerrainParams(terrainParams)
        
        // Add resort boundary
        try style.addSource(GeoJSONSource(id: "resort-boundary", data: HeavenlyData.boundaries))
        try style.addLayer(FillLayer(id: "resort-boundary-layer", source: "resort-boundary") { layer in
            layer.fillColor = .constant(StyleColor(.systemGray.withAlphaComponent(0.1)))
            layer.fillOutlineColor = .constant(StyleColor(.systemGray))
        })
        
        // Add ski runs with difficulty-based styling
        try style.addSource(GeoJSONSource(id: "ski-runs", data: HeavenlyData.runs))
        
        // Add layers for each difficulty level
        try style.addLayer(FillLayer(id: "ski-runs-green", source: "ski-runs") { layer in
            layer.filter = Exp(.eq) {
                "$type"
                "green"
            }
            layer.fillColor = .constant(StyleColor(.systemGreen.withAlphaComponent(0.3)))
            layer.fillOutlineColor = .constant(StyleColor(.systemGreen))
        })
        
        try style.addLayer(FillLayer(id: "ski-runs-blue", source: "ski-runs") { layer in
            layer.filter = Exp(.eq) {
                "$type"
                "blue"
            }
            layer.fillColor = .constant(StyleColor(.systemBlue.withAlphaComponent(0.3)))
            layer.fillOutlineColor = .constant(StyleColor(.systemBlue))
        })
        
        try style.addLayer(FillLayer(id: "ski-runs-black", source: "ski-runs") { layer in
            layer.filter = Exp(.eq) {
                "$type"
                "black"
            }
            layer.fillColor = .constant(StyleColor(.black.withAlphaComponent(0.3)))
            layer.fillOutlineColor = .constant(StyleColor(.black))
        })
        
        // Add lifts with type-based styling
        try style.addSource(GeoJSONSource(id: "ski-lifts", data: HeavenlyData.lifts))
        
        // Style for gondolas
        try style.addLayer(LineLayer(id: "ski-lifts-gondola", source: "ski-lifts") { layer in
            layer.filter = Exp(.eq) {
                "$type"
                "gondola"
            }
            layer.lineColor = .constant(StyleColor(.red))
            layer.lineWidth = .constant(3)
            layer.lineDasharray = .constant([2, 1])
        })
        
        // Style for chairlifts
        try style.addLayer(LineLayer(id: "ski-lifts-chairlift", source: "ski-lifts") { layer in
            layer.filter = Exp(.eq) {
                "$type"
                "chairlift"
            }
            layer.lineColor = .constant(StyleColor(.red))
            layer.lineWidth = .constant(2)
        })
        
        // Enhance atmosphere effect
        try style.setAtmosphere(Atmosphere(
            color: .init(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0),
            highColor: .init(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0),
            horizonBlend: 0.4,
            spaceColor: .init(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0),
            starIntensity: 0.0
        ))
        
        // Add sky layer
        try style.setSky(Sky(
            atmosphereColor: .init(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0),
            atmosphereSun: [0.0, 0.0],
            atmosphereSunIntensity: 15.0,
            gradient: [
                0.0: .init(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0),
                0.5: .init(red: 0.7, green: 0.8, blue: 1.0, alpha: 1.0),
                1.0: .init(red: 0.6, green: 0.7, blue: 1.0, alpha: 1.0)
            ]
        ))
    }
} 