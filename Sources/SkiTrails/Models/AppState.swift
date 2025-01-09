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
            
            // Debug logging
            if EnvConfig.isDebugMode {
                print("\n=== Resort Data Debug Info ===")
                print("Resort: \(resort.name)")
                print("Location: (\(resort.location.latitude), \(resort.location.longitude))")
                print("\nLifts (\(resort.lifts.count)):")
                for lift in resort.lifts {
                    print("- \(lift.name) at (\(lift.latitude), \(lift.longitude))")
                }
                print("\nRuns (\(resort.runs.count)):")
                for run in resort.runs {
                    print("- \(run.name) (\(run.difficulty))")
                    print("  Top: (\(run.topLatitude), \(run.topLongitude))")
                    print("  Bottom: (\(run.bottomLatitude), \(run.bottomLongitude))")
                    print("  Length: \(run.length)m, Drop: \(run.verticalDrop)m")
                }
                print("==============================\n")
            }
            
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
            
            // Debug print the graph
            if EnvConfig.isDebugMode {
                await RoutingEngine.shared.debugPrintGraph()
            }
            
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
    let latitude: Double
    let longitude: Double
    
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
    let latitude: Double
    let longitude: Double
    let topLatitude: Double
    let topLongitude: Double
    let bottomLatitude: Double
    let bottomLongitude: Double
    
    enum Status: String, Codable {
        case open
        case closed
        case grooming
    }
    
    // Default to main coordinates if top/bottom not provided
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        difficulty = try container.decode(SkiDifficulty.self, forKey: .difficulty)
        status = try container.decode(Status.self, forKey: .status)
        length = try container.decode(Double.self, forKey: .length)
        verticalDrop = try container.decode(Double.self, forKey: .verticalDrop)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        
        // Try to decode top/bottom coordinates, fall back to main coordinates
        topLatitude = try container.decodeIfPresent(Double.self, forKey: .topLatitude) ?? latitude
        topLongitude = try container.decodeIfPresent(Double.self, forKey: .topLongitude) ?? longitude
        bottomLatitude = try container.decodeIfPresent(Double.self, forKey: .bottomLatitude) ?? latitude
        bottomLongitude = try container.decodeIfPresent(Double.self, forKey: .bottomLongitude) ?? longitude
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