import SwiftUI
import MapboxMaps

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            ZStack {
                // 3D Map View
                MapView(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)
                
                // Overlay Controls
                VStack {
                    // Top Bar with Resort Info and Weather
                    TopBarView(resort: appState.selectedResort)
                    
                    Spacer()
                    
                    // Bottom Controls
                    if let activeRoute = appState.activeRoute {
                        RouteOverlayView(route: activeRoute)
                    } else {
                        ControlPanelView(viewModel: viewModel)
                    }
                }
                .padding()
                
                // Loading Overlay
                if appState.isLoading {
                    LoadingView()
                }
                
                // Error Alert
                if let error = appState.error {
                    ErrorAlertView(error: error) {
                        appState.clearError()
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                RouteDetailView(route: route)
            }
        }
    }
}

// MARK: - Supporting Views
struct TopBarView: View {
    let resort: Resort?
    
    var body: some View {
        HStack {
            if let resort = resort {
                VStack(alignment: .leading) {
                    Text(resort.name)
                        .font(.headline)
                    if let weather = resort.weather {
                        HStack {
                            Text("\(Int(weather.temperature))°")
                            Text("Snow: \(Int(weather.snowDepth))cm")
                        }
                        .font(.subheadline)
                    }
                }
            } else {
                Text("Select a Resort")
                    .font(.headline)
            }
            
            Spacer()
            
            Button(action: {
                // Open settings/filters
            }) {
                Image(systemName: "slider.horizontal.3")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
}

struct ControlPanelView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: ContentViewModel
    @State private var showDebugPanel = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Debug Controls (only in debug mode)
            if EnvConfig.isDebugMode {
                Button(action: {
                    // Load Palisades Tahoe as a test resort
                    Task {
                        await appState.loadResort(id: "palisades")
                    }
                }) {
                    Label("Load Test Resort", systemName: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                
                Button(action: {
                    showDebugPanel.toggle()
                }) {
                    Label("Debug Controls", systemName: "ladybug.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.purple)
                
                if showDebugPanel {
                    VStack(spacing: 8) {
                        Text("Location Simulation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Base Location (Palisades Tahoe)
                        Button(action: {
                            simulateLocation(latitude: 39.1911, longitude: -120.2356)
                        }) {
                            Label("Base Lodge", systemName: "house.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        
                        // Top of KT-22
                        Button(action: {
                            simulateLocation(latitude: 39.1967, longitude: -120.2385)
                        }) {
                            Label("KT-22 Peak", systemName: "mountain.2.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        
                        // Current Location Info
                        if let location = appState.locationManager.currentLocation {
                            Text("Current Location:")
                                .font(.caption)
                            Text(String(format: "Lat: %.4f", location.coordinate.latitude))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "Lon: %.4f", location.coordinate.longitude))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "Accuracy: ±%.0fm", location.horizontalAccuracy))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button(action: {
                    appState.locationManager.startUpdatingLocation()
                }) {
                    Label("Locate Me", systemName: "location.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }
            
            // Difficulty Filter
            HStack {
                ForEach(SkiDifficulty.allCases, id: \.self) { difficulty in
                    DifficultyButton(
                        difficulty: difficulty,
                        isSelected: appState.selectedDifficulty == difficulty
                    ) {
                        appState.selectedDifficulty = difficulty
                    }
                }
            }
            
            // Navigation Button
            Button(action: {
                // Start navigation mode
                if let resort = appState.selectedResort,
                   let userLocation = appState.locationManager.currentLocation {
                    Task {
                        // Navigate from current location to KT-22 peak
                        let destination = CLLocationCoordinate2D(
                            latitude: 39.1967,
                            longitude: -120.2385
                        )
                        await appState.startNavigation(
                            from: userLocation.coordinate,
                            to: destination,
                            viewModel: viewModel
                        )
                    }
                }
            }) {
                Label("Start Navigation", systemName: "location.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.selectedResort == nil || appState.locationManager.currentLocation == nil)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
    
    private func simulateLocation(latitude: Double, longitude: Double) {
        // For testing in simulator, we'll just set the location directly
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 2000, // Approximate elevation for Palisades Tahoe
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            appState.locationManager.currentLocation = location
        }
    }
}

struct DifficultyButton: View {
    let difficulty: SkiDifficulty
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(difficulty.color)
                .frame(width: 30, height: 30)
                .overlay {
                    if isSelected {
                        Circle()
                            .strokeBorder(.white, lineWidth: 2)
                    }
                }
        }
    }
}

struct RouteOverlayView: View {
    let route: Route
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Route")
                .font(.headline)
            
            HStack {
                Label("\(Int(route.totalDistance))m", systemName: "ruler")
                Spacer()
                Label(formatDuration(route.estimatedTime), systemName: "clock")
            }
            .font(.subheadline)
            
            Button("End Navigation") {
                // End navigation mode
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
    
    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: timeInterval) ?? ""
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
        }
        .ignoresSafeArea()
    }
}

struct ErrorAlertView: View {
    let error: Error
    let dismissAction: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                
                Text("Error")
                    .font(.headline)
                
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                
                Button("Dismiss") {
                    dismissAction()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .padding()
            
            Spacer()
        }
        .background(Color.black.opacity(0.4))
        .ignoresSafeArea()
    }
}

// MARK: - MapView
struct MapView: UIViewRepresentable {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject private var appState: AppState
    
    func makeUIView(context: Context) -> MapView {
        let mapView = MapView(frame: .zero)
        mapView.mapboxMap.loadStyleURI(.outdoors)
        
        // Configure the map view
        mapView.ornaments.options.compass.visibility = .visible
        mapView.ornaments.options.scaleBar.visibility = .visible
        
        // Enable user location tracking with custom puck
        let locationOptions = LocationOptions()
        locationOptions.puckType = .puck2D(
            Puck2DConfiguration(
                topImage: nil,
                bearingImage: nil,
                shadowImage: nil,
                scale: 1.0,
                showsAccuracyRing: true
            )
        )
        mapView.location.options = locationOptions
        
        // Set initial camera position
        let cameraOptions = CameraOptions(
            center: viewModel.mapCamera.center,
            zoom: viewModel.mapCamera.zoom,
            bearing: viewModel.mapCamera.bearing,
            pitch: viewModel.mapCamera.pitch
        )
        mapView.mapboxMap.setCamera(to: cameraOptions)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MapView, context: Context) {
        // Update camera if we have a user location
        if let location = appState.locationManager.currentLocation {
            // Only update camera if it's significantly different
            let currentCenter = mapView.mapboxMap.cameraState.center
            let distance = location.coordinate.distance(to: currentCenter)
            
            if distance > 100 { // Update if more than 100 meters away
                let cameraOptions = CameraOptions(
                    center: location.coordinate,
                    zoom: 15,
                    bearing: 0,
                    pitch: 45
                )
                mapView.mapboxMap.setCamera(to: cameraOptions)
            }
        }
        
        // Update route line if we have coordinates
        if !viewModel.routeCoordinates.isEmpty {
            updateRouteLine(on: mapView)
            
            // Focus camera on the entire route
            let coordinates = viewModel.routeCoordinates
            if coordinates.count > 1 {
                let bounds = coordinates.reduce(CoordinateBounds(
                    southwest: coordinates[0],
                    northeast: coordinates[0]
                )) { bounds, coordinate in
                    bounds.extend(coordinate)
                }
                
                // Add some padding around the route
                let camera = mapView.mapboxMap.camera(
                    for: bounds,
                    padding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100),
                    bearing: 0,
                    pitch: 45
                )
                mapView.mapboxMap.setCamera(to: camera)
            }
        } else {
            // Remove route line if no coordinates
            removeRouteLine(from: mapView)
        }
    }
    
    private func updateRouteLine(on mapView: MapView) {
        let coordinates = viewModel.routeCoordinates
        let lineString = LineString(coordinates)
        
        let source = GeoJSONSource()
        source.data = .feature(Feature(geometry: .lineString(lineString)))
        
        let sourceID = "route-source"
        let layerID = "route-layer"
        
        if mapView.mapboxMap.style.sourceExists(withId: sourceID) {
            try? mapView.mapboxMap.style.updateGeoJSONSource(
                withId: sourceID,
                geoJSON: .feature(Feature(geometry: .lineString(lineString)))
            )
        } else {
            try? mapView.mapboxMap.style.addSource(source, id: sourceID)
            
            var layer = LineLayer(id: layerID)
            layer.source = sourceID
            layer.lineColor = .constant(StyleColor(.systemBlue))
            layer.lineWidth = .constant(4)
            layer.lineCap = .constant(.round)
            layer.lineJoin = .constant(.round)
            try? mapView.mapboxMap.style.addLayer(layer)
        }
    }
    
    private func removeRouteLine(from mapView: MapView) {
        let sourceID = "route-source"
        let layerID = "route-layer"
        
        if mapView.mapboxMap.style.layerExists(withId: layerID) {
            try? mapView.mapboxMap.style.removeLayer(withId: layerID)
        }
        
        if mapView.mapboxMap.style.sourceExists(withId: sourceID) {
            try? mapView.mapboxMap.style.removeSource(withId: sourceID)
        }
    }
}

// MARK: - ViewModel
class ContentViewModel: ObservableObject {
    @Published var mapCamera: MapCamera = .default
    @Published var selectedPoint: MapPoint?
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    
    struct MapCamera {
        var center: CLLocationCoordinate2D
        var zoom: Double
        var bearing: Double
        var pitch: Double
        
        static let `default` = MapCamera(
            center: CLLocationCoordinate2D(latitude: 39.1911, longitude: -120.2356),
            zoom: 14,
            bearing: 0,
            pitch: 60
        )
    }
    
    struct MapPoint: Identifiable {
        let id: String
        let coordinate: CLLocationCoordinate2D
        let type: PointType
        
        enum PointType {
            case lift(Lift)
            case run(Run)
            case waypoint
        }
    }
} 