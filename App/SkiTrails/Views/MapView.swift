import SwiftUI
import MapboxMaps
import SkiTrailsCore

struct SkiMapView: View {
    @StateObject private var viewModel = MapViewModel()
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        ZStack {
            MapViewRepresentable(
                selectedFeature: $viewModel.selectedFeature
            )
            
            if let feature = viewModel.selectedFeature {
                VStack {
                    Spacer()
                    FeatureDetailCard(feature: feature)
                        .padding()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct MapViewRepresentable: UIViewControllerRepresentable {
    @Binding var selectedFeature: MapFeature?
    
    func makeUIViewController(context: Context) -> MapViewController {
        let viewController = MapViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        // Update view controller if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MapViewControllerDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapViewController(_ controller: MapViewController, didSelect feature: MapFeature) {
            parent.selectedFeature = feature
        }
    }
}

class MapViewController: UIViewController {
    weak var delegate: MapViewControllerDelegate?
    private var mapView: MapboxMaps.MapView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
    }
    
    private func setupMapView() {
        do {
            let accessToken = try MapConfig.getMapboxAccessToken()
            let resourceOptions = ResourceOptions(accessToken: accessToken)
            let mapInitOptions = MapInitOptions(resourceOptions: resourceOptions)
            
            let mapView = MapboxMaps.MapView(frame: view.bounds, mapInitOptions: mapInitOptions)
            mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            view.addSubview(mapView)
            self.mapView = mapView
            
            // Configure map style and camera
            mapView.mapboxMap.loadStyleURI(.outdoors)
            
            // Set initial camera position
            let camera = CameraOptions(
                center: CLLocationCoordinate2D(latitude: 39.6403, longitude: -106.3742),
                zoom: 14,
                bearing: 0,
                pitch: 45
            )
            mapView.camera.fly(to: camera, duration: 0)
            
        } catch {
            print("Failed to initialize map: \(error.localizedDescription)")
        }
    }
}

protocol MapViewControllerDelegate: AnyObject {
    func mapViewController(_ controller: MapViewController, didSelect feature: MapFeature)
}

struct FeatureDetailCard: View {
    let feature: MapFeature
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(feature.name)
                .font(.headline)
            
            switch feature {
            case .run(let run):
                RunDetailView(run: run)
            case .lift(let lift):
                LiftDetailView(lift: lift)
            case .point(_, _, _):
                EmptyView()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct RunDetailView: View {
    let run: Run
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Difficulty:")
                Text(run.difficulty.rawValue.capitalized)
            }
            HStack {
                Text("Status:")
                Text(run.status.rawValue.capitalized)
            }
            HStack {
                Text("Length:")
                Text(String(format: "%.1f km", run.length / 1000))
            }
            HStack {
                Text("Vertical:")
                Text(String(format: "%.0f m", run.verticalDrop))
            }
        }
    }
}

struct LiftDetailView: View {
    let lift: Lift
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Status:")
                Text(lift.status.rawValue.capitalized)
            }
            HStack {
                Text("Capacity:")
                Text("\(lift.capacity) riders")
            }
            if let waitTime = lift.waitTime {
                HStack {
                    Text("Wait Time:")
                    Text(String(format: "%.0f min", waitTime / 60))
                }
            }
        }
    }
} 