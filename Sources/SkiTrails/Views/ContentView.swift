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
                        ControlPanelView()
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
                if let resort = appState.selectedResort {
                    Task {
                        // Test navigation from resort base to a random point
                        let baseLocation = CLLocationCoordinate2D(
                            latitude: resort.location.latitude,
                            longitude: resort.location.longitude
                        )
                        let randomPoint = CLLocationCoordinate2D(
                            latitude: baseLocation.latitude + 0.01,
                            longitude: baseLocation.longitude + 0.01
                        )
                        await appState.startNavigation(from: baseLocation, to: randomPoint)
                    }
                }
            }) {
                Label("Start Navigation", systemName: "location.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.selectedResort == nil)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
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
    
    func makeUIView(context: Context) -> MapView {
        let mapView = MapView(frame: .zero)
        mapView.mapboxMap.loadStyleURI(.outdoors)
        
        // Configure the map view
        // Add annotations for lifts and runs
        // Set up gesture recognizers
        
        return mapView
    }
    
    func updateUIView(_ mapView: MapView, context: Context) {
        // Update map annotations and overlays based on viewModel state
    }
}

// MARK: - ViewModel
class ContentViewModel: ObservableObject {
    @Published var mapCamera: MapCamera = .default
    @Published var selectedPoint: MapPoint?
    
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