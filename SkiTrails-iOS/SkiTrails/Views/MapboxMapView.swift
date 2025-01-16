import SwiftUI
import MapboxMaps
import SkiTrailsCore
import CoreLocation

struct MapboxMapView: UIViewRepresentable {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: MapViewModel
    
    func makeUIView(context: Context) -> MapView {
        let resourceOptions = ResourceOptions(accessToken: EnvConfig.mapboxAccessToken)
        let mapInitOptions = MapInitOptions(resourceOptions: resourceOptions)
        let mapView = MapView(frame: .zero, mapInitOptions: mapInitOptions)
        
        mapView.location.delegate = context.coordinator
        mapView.gestures.delegate = context.coordinator
        
        mapView.mapboxMap.onNext(event: .mapLoaded) { _ in
            viewModel.mapLoaded = true
            setupMapLayers(mapView)
        }
        
        viewModel.mapView = mapView
        return mapView
    }
    
    func updateUIView(_ mapView: MapView, context: Context) {
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if let resort = appState.selectedResort {
            mapView.camera.fly(to: viewModel.getCameraOptions(for: resort.coordinate), duration: 1.0)
            updateMapFeatures(mapView, resort: resort)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func setupMapLayers(_ mapView: MapView) {
        do {
            let liftSource = createLiftSource()
            let runSource = createRunSource()
            try mapView.mapboxMap.style.addSource(liftSource, id: "lifts")
            try mapView.mapboxMap.style.addSource(runSource, id: "runs")
            try mapView.mapboxMap.style.addLayer(createLiftLayer())
            try mapView.mapboxMap.style.addLayer(createRunLayer())
        } catch {
            Task {
                await ErrorHandler.shared.handle(error)
            }
        }
    }
    
    private func updateMapFeatures(_ mapView: MapView, resort: Resort) {
        do {
            var liftSource = GeoJSONSource()
            liftSource.data = .featureCollection(createLiftFeatures(resort))
            try mapView.mapboxMap.style.removeSource(withId: "lifts")
            try mapView.mapboxMap.style.addSource(liftSource, id: "lifts")
            
            var runSource = GeoJSONSource()
            runSource.data = .featureCollection(createRunFeatures(resort))
            try mapView.mapboxMap.style.removeSource(withId: "runs")
            try mapView.mapboxMap.style.addSource(runSource, id: "runs")
        } catch {
            Task {
                await ErrorHandler.shared.handle(error)
            }
        }
    }
    
    private func createLiftSource() -> GeoJSONSource {
        var source = GeoJSONSource()
        source.data = .featureCollection(FeatureCollection(features: []))
        return source
    }
    
    private func createRunSource() -> GeoJSONSource {
        var source = GeoJSONSource()
        source.data = .featureCollection(FeatureCollection(features: []))
        return source
    }
    
    private func createLiftLayer() -> LineLayer {
        var layer = LineLayer(id: "lifts")
        layer.source = "lifts"
        layer.lineColor = .constant(.init(UIColor.systemRed))
        layer.lineWidth = .constant(3)
        return layer
    }
    
    private func createRunLayer() -> LineLayer {
        var layer = LineLayer(id: "runs")
        layer.source = "runs"
        layer.lineColor = .expression(Exp(.match) {
            Exp(.get) { "difficulty" }
            "beginner"
            UIColor.systemGreen
            "intermediate"
            UIColor.systemBlue
            "advanced"
            UIColor.black
            "expert"
            UIColor.systemPurple
            UIColor.systemGray
        })
        layer.lineWidth = .constant(3)
        return layer
    }
    
    private func createLiftFeatures(_ resort: Resort) -> FeatureCollection {
        let features = resort.lifts.map { lift -> Feature in
            let coordinates = [
                lift.startLocation.coordinate,
                lift.endLocation.coordinate
            ]
            let geometry = LineString(coordinates)
            var feature = Feature(geometry: geometry)
            feature.properties = [
                "id": .string(lift.id.rawValue),
                "name": .string(lift.name),
                "status": .string(lift.status.rawValue),
                "type": .string("lift")
            ]
            return feature
        }
        return FeatureCollection(features: features)
    }
    
    private func createRunFeatures(_ resort: Resort) -> FeatureCollection {
        let features = resort.runs.map { run -> Feature in
            let coordinates = [
                run.startLocation.coordinate,
                run.endLocation.coordinate
            ]
            let geometry = LineString(coordinates)
            var feature = Feature(geometry: geometry)
            feature.properties = [
                "id": .string(run.id.rawValue),
                "name": .string(run.name),
                "difficulty": .string(run.difficulty.rawValue),
                "status": .string(run.status.rawValue),
                "type": .string("run")
            ]
            return feature
        }
        return FeatureCollection(features: features)
    }
    
    class Coordinator: NSObject, LocationPermissionsDelegate, GestureManagerDelegate {
        func gestureManager(_ gestureManager: MapboxMaps.GestureManager, didEnd gestureType: MapboxMaps.GestureType, willAnimate: Bool) {
            // Handle gesture end - for now just ensure map is marked as loaded
            if !parent.viewModel.mapLoaded {
                parent.viewModel.mapLoaded = true
            }
        }
        
        var parent: MapboxMapView
        
        init(_ parent: MapboxMapView) {
            self.parent = parent
            super.init()
        }
        
        func locationManager(_ locationManager: MapboxMaps.LocationManager, didChangeAccuracyAuthorization accuracyAuthorization: CLAccuracyAuthorization) {
            switch accuracyAuthorization {
            case .fullAccuracy:
                parent.appState.locationManager.startUpdatingLocation()
            case .reducedAccuracy:
                Task {
                    await ErrorHandler.shared.handle(UserFacingError(
                        title: "Reduced Location Accuracy",
                        message: "Please enable precise location for better navigation."
                    ))
                }
            @unknown default:
                break
            }
        }
        
        func gestureManager(_ gestureManager: MapboxMaps.GestureManager, didBegin gestureType: MapboxMaps.GestureType) {}
        
        func gestureManager(_ gestureManager: MapboxMaps.GestureManager, didEnd gesture: GestureType) {
            guard case .singleTap = gesture,
                  let mapView = parent.viewModel.mapView else {
                return
            }
            
            let point = gestureManager.singleTapGestureRecognizer.location(in: mapView)
            let options = RenderedQueryOptions(layerIds: ["lifts", "runs"], filter: nil)
            mapView.mapboxMap.queryRenderedFeatures(at: point, options: options) { result in
                switch result {
                case .success(let features):
                    guard let feature = features.first,
                          let properties = feature.feature.properties,
                          let typeValue = properties["type"],
                          let type = typeValue?.rawValue as? String,
                          let idValue = properties["id"],
                          let id = idValue?.rawValue as? String else {
                        return
                    }
                    
                    if let resort = self.parent.appState.selectedResort {
                        let mapFeature: MapFeature?
                        switch type {
                        case "lift":
                            mapFeature = resort.lifts.first { $0.id.rawValue == id }.map { .lift($0) }
                        case "run":
                            mapFeature = resort.runs.first { $0.id.rawValue == id }.map { .run($0) }
                        default:
                            mapFeature = nil
                        }
                        
                        if let mapFeature {
                            self.parent.viewModel.handleFeatureSelection(mapFeature)
                        }
                    }
                    
                case .failure(let error):
                    Task {
                        await ErrorHandler.shared.handle(error)
                    }
                }
            }
        }
        
        func gestureManager(_ gestureManager: GestureManager, didUpdate gestureType: GestureType) {
            // No implementation needed
        }
        
        func gestureManager(_ gestureManager: GestureManager, didCancel gestureType: GestureType) {
            // No implementation needed
        }
        
        func gestureManager(_ gestureManager: GestureManager, didEndAnimatingFor gestureType: GestureType) {
            if let mapView = parent.viewModel.mapView {
                parent.viewModel.handleMapUpdate(mapView)
            }
        }
    }
} 
