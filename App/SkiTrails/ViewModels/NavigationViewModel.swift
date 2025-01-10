import SwiftUI
import SkiTrailsCore
import Combine
import CoreLocation

@MainActor
class NavigationViewModel: ObservableObject {
    @Published private(set) var currentRoute: Route?
    @Published private(set) var isNavigating = false
    @Published private(set) var isCalculating = false
    @Published private(set) var error: Error?
    
    private let routingEngine: RoutingEngine
    
    init() {
        self.routingEngine = RoutingEngine.shared
    }
    
    func startNavigation(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        difficulty: SkiDifficulty = .intermediate,
        preferences: RoutePreferences = RoutePreferences(
            avoidCrowds: false,
            preferLessStrenuous: false,
            maxWaitTime: nil
        )
    ) async {
        isCalculating = true
        error = nil
        
        do {
            let route = try await routingEngine.findRoute(
                from: start,
                to: end,
                difficulty: difficulty,
                preferences: preferences
            )
            currentRoute = route
            isNavigating = true
        } catch {
            self.error = error
        }
        
        isCalculating = false
    }
    
    func endNavigation() {
        isNavigating = false
        currentRoute = nil
        error = nil
    }
    
    enum NavigationError: LocalizedError {
        case noRouteFound
        
        var errorDescription: String? {
            switch self {
            case .noRouteFound:
                return "No valid route found between the selected points"
            }
        }
    }
} 