import SwiftUI
import SkiTrailsCore
import Combine

@MainActor
class NavigationViewModel: ObservableObject {
    @Published private(set) var currentRoute: RoutingEngine.Route?
    @Published private(set) var isNavigating = false
    @Published private(set) var isCalculating = false
    @Published private(set) var error: Error?
    
    private let routingEngine: RoutingEngine
    
    init(routingEngine: RoutingEngine = RoutingEngine()) {
        self.routingEngine = routingEngine
    }
    
    func startNavigation(from start: Location, to end: Location, in resort: Resort) async {
        isCalculating = true
        error = nil
        
        do {
            if let route = await routingEngine.findRoute(from: start, to: end, in: resort) {
                currentRoute = route
                isNavigating = true
            } else {
                throw NavigationError.noRouteFound
            }
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