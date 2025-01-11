import SwiftUI
import CoreLocation

@MainActor
class ContentViewModel: ObservableObject {
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    func handleError(_ error: Error) {
        self.error = error
    }
    
    func clearRoute() {
        routeCoordinates = []
    }
} 