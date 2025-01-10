import SwiftUI
import MapboxMaps
import SkiTrailsCore

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                mainContent
            }
        } else {
            NavigationView {
                mainContent
            }
            .navigationViewStyle(.stack)
        }
    }
    
    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            ResortListView()
                .tabItem {
                    Label("Resorts", systemImage: "mountain.2")
                }
                .tag(0)
            
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(1)
            
            TrailStatusView()
                .tabItem {
                    Label("Trails", systemImage: "figure.skiing.downhill")
                }
                .tag(2)
            
            NavigationView()
                .tabItem {
                    Label("Navigation", systemImage: "location.north.circle")
                }
                .tag(3)
        }
    }
}

struct ResortListView: View {
    @StateObject private var viewModel = ResortViewModel()
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(appState.resorts) { resort in
                        ResortRowView(resort: resort)
                            .onTapGesture {
                                viewModel.selectResort(resort)
                            }
                    }
                }
            }
        }
        .navigationTitle("Ski Resorts")
        .task {
            await appState.loadResorts()
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            ),
            presenting: viewModel.error
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

struct ResortRowView: View {
    let resort: Resort
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(resort.name)
                .font(.headline)
            
            HStack {
                Image(systemName: "snow")
                Text("Base: \(resort.snowDepth.base)″")
                Text("•")
                Text("New: \(resort.snowDepth.newSnow)″")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            HStack {
                StatusIndicator(
                    count: resort.liftStatus.open,
                    total: resort.liftStatus.total,
                    type: "Lifts"
                )
                
                Spacer()
                
                StatusIndicator(
                    count: resort.runStatus.open,
                    total: resort.runStatus.total,
                    type: "Runs"
                )
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}

struct StatusIndicator: View {
    let count: Int
    let total: Int
    let type: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(count > 0 ? .green : .red)
                .frame(width: 8, height: 8)
            
            Text("\(count)/\(total) \(type)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    
    // Heavenly Mountain Resort coordinates
    private let heavenlyCoordinates = CLLocationCoordinate2D(
        latitude: 38.9353,
        longitude: -119.9400
    )
    
    var body: some View {
        MapboxMapView(viewModel: viewModel)
            .onAppear {
                viewModel.setCamera(
                    center: heavenlyCoordinates,
                    zoom: 13,
                    bearing: 0,
                    pitch: 60
                )
            }
            .navigationTitle("Resort Map")
    }
}

struct MapboxMapView: UIViewRepresentable {
    let initialCoordinates: CLLocationCoordinate2D
    let initialZoom: Double
    let initialPitch: Double
    let initialBearing: Double
    
    func makeUIView(context: Context) -> MapView {
        let accessToken: String
        do {
            accessToken = try MapConfig.getMapboxAccessToken()
        } catch {
            fatalError("Mapbox access token not configured: \(error.localizedDescription)")
        }
        
        let options = MapInitOptions(
            resourceOptions: ResourceOptions(accessToken: accessToken),
            cameraOptions: CameraOptions(
                center: initialCoordinates,
                zoom: initialZoom,
                pitch: initialPitch,
                bearing: initialBearing
            ),
            styleURI: .outdoors
        )
        
        let mapView = MapView(frame: .zero, mapInitOptions: options)
        
        // Configure gestures
        mapView.gestures.options.rotateEnabled = true
        mapView.gestures.options.pinchZoomEnabled = true
        mapView.gestures.options.pitchEnabled = true
        mapView.gestures.options.doubleTapToZoomInEnabled = true
        mapView.gestures.options.doubleTouchToZoomOutEnabled = true
        mapView.gestures.options.quickZoomEnabled = true
        
        // Set zoom constraints for appropriate mountain viewing
        mapView.mapboxMap.setCamera(to: CameraOptions(
            minZoom: 12,
            maxZoom: 18,
            minPitch: 0,
            maxPitch: 85
        ))
        
        // Configure the map style after loading
        mapView.mapboxMap.onStyleLoaded.observe { _ in
            try? self.configureMapStyle(mapView)
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: MapView, context: Context) {
        // Update view if needed
    }
    
    private func configureMapStyle(_ mapView: MapView) throws {
        let style = mapView.mapboxMap.style
        
        // Add terrain source and configure 3D terrain
        try style.addSource(TerrainSource(id: "terrain", configuration: .init(url: "mapbox://mapbox.mapbox-terrain-dem-v1")))
        try style.setTerrain(Terrain(sourceId: "terrain", configuration: .init(exaggeration: 1.5)))
        
        // Add resort boundary
        try style.addSource(GeoJSONSource(id: "resort-boundary", configuration: .init(data: HeavenlyData.boundaries)))
        try style.addLayer(FillLayer(id: "resort-boundary-layer", source: "resort-boundary", configuration: .init(
            fillColor: .constant(.init(UIColor.systemGray.withAlphaComponent(0.1))),
            fillOutlineColor: .constant(.init(UIColor.systemGray))
        )))
        
        // Add ski runs with difficulty-based styling
        try style.addSource(GeoJSONSource(id: "ski-runs", configuration: .init(data: HeavenlyData.runs)))
        
        // Add layers for each difficulty level
        try style.addLayer(FillLayer(id: "ski-runs-green", source: "ski-runs", configuration: .init(
            filter: .eq(.property("difficulty"), .string("green")),
            fillColor: .constant(.init(UIColor.systemGreen.withAlphaComponent(0.3))),
            fillOutlineColor: .constant(.init(UIColor.systemGreen))
        )))
        
        try style.addLayer(FillLayer(id: "ski-runs-blue", source: "ski-runs", configuration: .init(
            filter: .eq(.property("difficulty"), .string("blue")),
            fillColor: .constant(.init(UIColor.systemBlue.withAlphaComponent(0.3))),
            fillOutlineColor: .constant(.init(UIColor.systemBlue))
        )))
        
        try style.addLayer(FillLayer(id: "ski-runs-black", source: "ski-runs", configuration: .init(
            filter: .eq(.property("difficulty"), .string("black")),
            fillColor: .constant(.init(UIColor.black.withAlphaComponent(0.3))),
            fillOutlineColor: .constant(.init(UIColor.black))
        )))
        
        // Add lifts with type-based styling
        try style.addSource(GeoJSONSource(id: "ski-lifts", configuration: .init(data: HeavenlyData.lifts)))
        
        // Style for gondolas
        try style.addLayer(LineLayer(id: "ski-lifts-gondola", source: "ski-lifts", configuration: .init(
            filter: .eq(.property("type"), .string("gondola")),
            lineColor: .constant(.init(UIColor.red)),
            lineWidth: .constant(3),
            lineDasharray: .constant([2, 1])
        )))
        
        // Style for chairlifts
        try style.addLayer(LineLayer(id: "ski-lifts-chairlift", source: "ski-lifts", configuration: .init(
            filter: .eq(.property("type"), .string("chairlift")),
            lineColor: .constant(.init(UIColor.red)),
            lineWidth: .constant(2)
        )))
        
        // Enhance atmosphere effect for mountain visualization
        try style.setAtmosphere(Atmosphere(
            color: UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0),
            highColor: UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0),
            horizonBlend: 0.4,
            spaceColor: UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0),
            starIntensity: 0.0
        ))
        
        // Add sky layer for better 3D effect
        try style.setSky(Sky(
            atmosphereColor: UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0),
            atmosphereSun: [0.0, 0.0],
            atmosphereSunIntensity: 15.0,
            gradient: [
                0.0: UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0),
                0.5: UIColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1.0),
                1.0: UIColor(red: 0.6, green: 0.7, blue: 1.0, alpha: 1.0)
            ]
        ))
    }
}

struct TrailStatusView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ResortViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let resort = viewModel.selectedResort {
                List {
                    Section("Lifts") {
                        ForEach(resort.lifts) { lift in
                            LiftStatusRow(lift: lift)
                        }
                    }
                    
                    Section("Runs") {
                        ForEach(resort.runs) { run in
                            RunStatusRow(run: run)
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Resort Selected",
                    systemImage: "mountain.2",
                    description: Text("Select a resort to view trail status")
                )
            }
        }
        .navigationTitle("Trail Status")
        .refreshable {
            if let resort = viewModel.selectedResort {
                await viewModel.refreshResortStatus(resort.id)
            }
        }
    }
}

struct LiftStatusRow: View {
    let lift: Lift
    
    var body: some View {
        HStack {
            Text(lift.name)
            
            Spacer()
            
            StatusBadge(status: lift.status)
        }
    }
}

struct RunStatusRow: View {
    let run: Run
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(run.name)
                
                HStack {
                    DifficultyIndicator(difficulty: run.difficulty)
                    Text("\(Int(run.length))m • \(Int(run.verticalDrop))m vert")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            StatusBadge(status: run.status)
        }
    }
}

struct StatusBadge: View {
    let status: Status
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .clipShape(Capsule())
    }
}

struct DifficultyIndicator: View {
    let difficulty: SkiDifficulty
    
    var body: some View {
        Image(systemName: difficulty.symbolName)
            .foregroundColor(difficulty.color)
    }
}

private extension Status {
    var color: Color {
        switch self {
        case .open:
            return .green
        case .closed:
            return .red
        case .hold:
            return .orange
        case .scheduled:
            return .blue
        }
    }
}

private extension SkiDifficulty {
    var symbolName: String {
        switch self {
        case .beginner:
            return "circle.fill"
        case .intermediate:
            return "square.fill"
        case .advanced:
            return "diamond.fill"
        case .expert:
            return "diamond.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .beginner:
            return .green
        case .intermediate:
            return .blue
        case .advanced:
            return .black
        case .expert:
            return .black
        }
    }
}

struct NavigationView: View {
    @StateObject private var navigationViewModel = NavigationViewModel()
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            if navigationViewModel.isNavigating {
                ActiveNavigationView(viewModel: navigationViewModel)
            } else {
                NavigationSetupView(viewModel: navigationViewModel)
            }
        }
        .navigationTitle("Navigation")
        .alert(
            "Error",
            isPresented: Binding(
                get: { navigationViewModel.error != nil },
                set: { if !$0 { navigationViewModel.error = nil } }
            ),
            presenting: navigationViewModel.error
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

struct NavigationSetupView: View {
    @ObservedObject var viewModel: NavigationViewModel
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        List {
            Section("Start Point") {
                if let location = viewModel.startPoint {
                    LocationRow(
                        coordinate: location,
                        title: "Current Location",
                        subtitle: "Tap to change"
                    )
                } else {
                    Button("Set Start Point") {
                        Task {
                            await viewModel.setStartPoint()
                        }
                    }
                }
            }
            
            Section("End Point") {
                if let location = viewModel.endPoint {
                    LocationRow(
                        coordinate: location,
                        title: "Destination",
                        subtitle: "Tap to change"
                    )
                } else {
                    Button("Set End Point") {
                        viewModel.isSelectingEndPoint = true
                    }
                }
            }
            
            Section("Route Options") {
                Picker("Difficulty", selection: $viewModel.difficulty) {
                    ForEach(SkiDifficulty.allCases, id: \.self) { difficulty in
                        HStack {
                            DifficultyIndicator(difficulty: difficulty)
                            Text(difficulty.description)
                        }
                        .tag(difficulty)
                    }
                }
            }
            
            Section {
                Button("Start Navigation") {
                    Task {
                        await viewModel.startNavigation()
                    }
                }
                .disabled(!viewModel.canStartNavigation)
            }
        }
        .sheet(isPresented: $viewModel.isSelectingEndPoint) {
            MapSelectionView(
                coordinate: $viewModel.endPoint,
                title: "Select Destination"
            )
        }
    }
}

struct LocationRow: View {
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("(\(coordinate.latitude.formatted()), \(coordinate.longitude.formatted()))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

private extension SkiDifficulty {
    var description: String {
        switch self {
        case .beginner:
            return "Beginner (Green)"
        case .intermediate:
            return "Intermediate (Blue)"
        case .advanced:
            return "Advanced (Black)"
        case .expert:
            return "Expert (Double Black)"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
} 