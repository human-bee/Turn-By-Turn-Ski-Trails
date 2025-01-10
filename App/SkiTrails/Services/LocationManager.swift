import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var currentLocation: CLLocation?
    
    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5 // Update location when user moves 5 meters
        manager.activityType = .fitness // Optimized for outdoor activities
        
        if EnvConfig.isDebugMode {
            print("[Location] Initial authorization status: \(authorizationStatus.rawValue)")
        }
    }
    
    func requestAuthorization() {
        if EnvConfig.isDebugMode {
            print("[Location] Requesting authorization...")
        }
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        if EnvConfig.isDebugMode {
            print("[Location] Starting location updates...")
        }
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        if EnvConfig.isDebugMode {
            print("[Location] Stopping location updates...")
        }
        manager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        if EnvConfig.isDebugMode {
            print("[Location] Authorization status changed to: \(status.rawValue)")
        }
        
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            // Automatically start updates if authorized
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.startUpdatingLocation()
            }
        }
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }
        
        // Only accept locations that are recent and accurate enough
        let locationAge = -location.timestamp.timeIntervalSinceNow
        guard locationAge < 5, // Less than 5 seconds old
              location.horizontalAccuracy >= 0,
              location.horizontalAccuracy < 50 // Accurate within 50 meters
        else {
            if EnvConfig.isDebugMode {
                print("[Location] Rejected update - Age: \(locationAge)s, Accuracy: \(location.horizontalAccuracy)m")
            }
            return
        }
        
        if EnvConfig.isDebugMode {
            print("[Location] Updated: (\(location.coordinate.latitude), \(location.coordinate.longitude)) ±\(Int(location.horizontalAccuracy))m")
        }
        
        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("[Location] Error: \(error.localizedDescription)")
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("[Location] Location services denied by user")
            case .locationUnknown:
                print("[Location] Unable to determine location")
            default:
                print("[Location] CoreLocation error: \(clError.code.rawValue)")
            }
        }
    }
} 