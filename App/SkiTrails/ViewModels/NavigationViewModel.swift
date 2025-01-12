import SwiftUI
import SkiTrailsCore
import CoreLocation

@MainActor
class NavigationViewModel: ObservableObject {
    @Published var skillLevel: Run.Difficulty = .intermediate
    @Published var avoidCrowds = false
    @Published var preferLessStrenuous = false
    @Published var showRouteSelection = false
    @Published var startPoint: Run?
    @Published var endPoint: Run?
    @Published var currentRoute: Route?
    @Published var isNavigating = false
    
    private let appState: AppState
    
    init(appState: AppState = .init()) {
        self.appState = appState
    }
    
    var canStartNavigation: Bool {
        endPoint != nil && (startPoint != nil || appState.locationManager.currentLocation != nil)
    }
    
    func startNavigation() async {
        guard let endPoint else { return }
        
        let preferences = RoutePreferences(
            avoidCrowds: avoidCrowds,
            preferLessStrenuous: preferLessStrenuous
        )
        
        do {
            if let startPoint {
                currentRoute = try await RoutingEngine.shared.findRoute(
                    from: CLLocationCoordinate2D(
                        latitude: startPoint.startLocation.latitude,
                        longitude: startPoint.startLocation.longitude
                    ),
                    to: CLLocationCoordinate2D(
                        latitude: endPoint.endLocation.latitude,
                        longitude: endPoint.endLocation.longitude
                    ),
                    difficulty: skillLevel,
                    preferences: preferences
                )
            } else if let currentLocation = appState.locationManager.currentLocation {
                // Use current location
                currentRoute = try await RoutingEngine.shared.findRoute(
                    from: currentLocation.coordinate,
                    to: CLLocationCoordinate2D(
                        latitude: endPoint.endLocation.latitude,
                        longitude: endPoint.endLocation.longitude
                    ),
                    difficulty: skillLevel,
                    preferences: preferences
                )
            } else {
                await ErrorHandler.shared.handle(NavigationError.noCurrentLocation)
                return
            }
            
            isNavigating = true
        } catch {
            await ErrorHandler.shared.handle(error)
        }
    }
    
    func stopNavigation() {
        isNavigating = false
        currentRoute = nil
        startPoint = nil
        endPoint = nil
    }
    
    enum NavigationError: LocalizedError {
        case noCurrentLocation
        
        var errorDescription: String? {
            switch self {
            case .noCurrentLocation:
                return "Unable to get current location. Please ensure location services are enabled."
            }
        }
    }
} 