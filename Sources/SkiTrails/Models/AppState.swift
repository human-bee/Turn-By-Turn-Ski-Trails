import SwiftUI
import Combine
import CoreLocation

@MainActor
class AppState: ObservableObject {
    // MARK: - Published Properties
    
    @Published var selectedResort: Resort?
    @Published var selectedDifficulty: SkiDifficulty?
    @Published var isLoading = false
    @Published var error: UserFacingError?
    
    // Navigation state
    @Published var navigationPath = NavigationPath()
    @Published var activeRoute: Route?
    
    // User preferences
    @Published var userSkillLevel: SkiDifficulty = .beginner
    @Published var preferLessStrenuous = false
    @Published var avoidCrowdedRuns = false
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let errorHandler = ErrorHandler.shared
    
    // MARK: - Initialization
    
    init() {
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    func clearError() {
        error = nil
    }
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    func handleError(_ error: Error, context: ErrorContext? = nil) async {
        self.error = await errorHandler.handleUserFacing(error, context: context)
    }
    
    // MARK: - Resort Data
    
    func loadResort(id: String) async {
        setLoading(true)
        defer { setLoading(false) }
        
        do {
            // Fetch resort info
            let resort = try await APIClient.shared.fetchResortInfo(id: id)
            
            // Start async tasks for weather and lift status
            async let weather = APIClient.shared.fetchWeather(for: resort)
            async let lifts = APIClient.shared.fetchLiftStatus(for: resort)
            
            // Wait for all data
            var updatedResort = resort
            updatedResort.weather = try await weather
            updatedResort.lifts = try await lifts
            
            // Update state
            selectedResort = updatedResort
            
            // Initialize routing engine with resort data
            await RoutingEngine.shared.buildGraph(for: updatedResort)
            
        } catch {
            await handleError(error, context: .api(endpoint: "resort/\(id)"))
        }
    }
    
    // MARK: - Navigation
    
    func startNavigation(
        from startPoint: CLLocationCoordinate2D,
        to endPoint: CLLocationCoordinate2D
    ) async {
        setLoading(true)
        defer { setLoading(false) }
        
        do {
            let preferences = RoutePreferences(
                avoidCrowds: avoidCrowdedRuns,
                preferLessStrenuous: preferLessStrenuous,
                maxWaitTime: nil
            )
            
            let route = try await RoutingEngine.shared.findRoute(
                from: startPoint,
                to: endPoint,
                difficulty: userSkillLevel,
                preferences: preferences
            )
            
            activeRoute = route
            
        } catch {
            await handleError(
                error,
                context: .navigation(
                    startPoint: startPoint,
                    endPoint: endPoint,
                    difficulty: userSkillLevel
                )
            )
        }
    }
    
    func endNavigation() {
        activeRoute = nil
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Add Combine subscriptions for real-time updates
        // For example, periodic weather updates or lift status changes
    }
}

// MARK: - Supporting Types
enum SkiDifficulty: String, CaseIterable {
    case beginner = "Green"
    case intermediate = "Blue"
    case advanced = "Black"
    case expert = "Double Black"
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .black
        case .expert: return .black
        }
    }
}

struct Resort: Identifiable, Codable {
    let id: String
    let name: String
    let location: Location
    var lifts: [Lift]
    var runs: [Run]
    var weather: WeatherInfo?
    
    struct Location: Codable {
        let latitude: Double
        let longitude: Double
        let altitude: Double
    }
}

struct Lift: Identifiable, Codable {
    let id: String
    let name: String
    var status: Status
    let capacity: Int
    let waitTime: Int?
    
    enum Status: String, Codable {
        case open
        case closed
        case hold
        case scheduled
    }
}

struct Run: Identifiable, Codable {
    let id: String
    let name: String
    let difficulty: SkiDifficulty
    var status: Status
    let length: Double // in meters
    let verticalDrop: Double // in meters
    
    enum Status: String, Codable {
        case open
        case closed
        case grooming
    }
}

struct WeatherInfo: Codable {
    let temperature: Double
    let snowDepth: Double
    let windSpeed: Double
    let visibility: Double
    let forecast: String
    let lastUpdated: Date
}

struct Route {
    let segments: [Segment]
    let totalDistance: Double
    let estimatedTime: TimeInterval
    let difficulty: SkiDifficulty
    
    struct Segment {
        let type: SegmentType
        let path: [Location]
        let distance: Double
        
        enum SegmentType {
            case run(Run)
            case lift(Lift)
            case connection
        }
        
        struct Location {
            let latitude: Double
            let longitude: Double
            let altitude: Double
        }
    }
} 