import SwiftUI
import Combine
import CoreLocation
import Foundation

// Import ViewModels
@_spi(Internal) import SkiTrailsCore

@MainActor
class AppState: ObservableObject {
    // MARK: - Published Properties
    
    @Published var locationManager = LocationManager()
    @Published var selectedResort: Resort?
    @Published var selectedDifficulty: SkiDifficulty?
    @Published var isLoading = false
    @Published var error: UserFacingError?
    
    // Navigation state
    @Published var navigationPath = NavigationPath()
    @Published var activeRoute: Route?
    
    // Route coordinates for navigation
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    
    // User preferences
    @Published var userSkillLevel: SkiDifficulty = .beginner
    @Published var preferLessStrenuous = false
    @Published var avoidCrowdedRuns = false
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let errorHandler = ErrorHandler.shared
    private var statusRefreshTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init() {
        setupSubscriptions()
        startStatusRefreshTimer()
        locationManager.requestAuthorization()
    }
    
    deinit {
        statusRefreshTask?.cancel()
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
    
    func refreshResortStatus() async {
        guard let resort = selectedResort else { return }
        
        do {
            // Re-fetch only the lifts for now, since we have no separate runs status API
            let updatedLifts = try await APIClient.shared.fetchLiftStatus(for: resort)
            
            // Merge updates
            var updatedResort = resort
            updatedResort.lifts = updatedLifts
            
            // Update state
            selectedResort = updatedResort
            
            // Re-build graph so closed lifts are excluded from routing
            await RoutingEngine.shared.buildGraph(for: updatedResort)
            
            if EnvConfig.isDebugMode {
                print("[Status Refresh] Lifts updated at \(Date())")
                await RoutingEngine.shared.debugPrintGraph()
            }
        } catch {
            await handleError(error, context: .api(endpoint: "refreshStatus"))
        }
    }
    
    // MARK: - Navigation
    
    func startNavigation(
        from startPoint: CLLocationCoordinate2D,
        to endPoint: CLLocationCoordinate2D
    ) async {
        do {
            guard let resort = selectedResort else {
                throw RoutingError.graphNotInitialized
            }
            
            // Calculate route
            let route = try await RoutingEngine.shared.findRoute(
                from: startPoint,
                to: endPoint,
                difficulty: userSkillLevel,
                preferences: RoutePreferences(
                    avoidCrowds: avoidCrowdedRuns,
                    preferLessStrenuous: preferLessStrenuous,
                    maxWaitTime: nil
                )
            )
            
            // Extract coordinates from route segments
            let routeCoordinates = route.segments.flatMap { segment in
                segment.path.map { location in
                    CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    )
                }
            }
            
            // Update state
            activeRoute = route
            self.routeCoordinates = routeCoordinates
            
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
        routeCoordinates = []
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Add Combine subscriptions for real-time updates
        // For example, periodic weather updates or lift status changes
    }
    
    private func startStatusRefreshTimer() {
        // Cancel any existing task
        statusRefreshTask?.cancel()
        
        // Start a new refresh task
        statusRefreshTask = Task {
            while !Task.isCancelled {
                do {
                    // Wait 60 seconds between refreshes
                    try await Task.sleep(nanoseconds: 60_000_000_000)
                    await refreshResortStatus()
                } catch {
                    // If Task is cancelled or fails, break the loop
                    break
                }
            }
        }
    }
}

// MARK: - Supporting Types
enum SkiDifficulty: String, CaseIterable, Comparable, Codable {
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
    
    static func < (lhs: SkiDifficulty, rhs: SkiDifficulty) -> Bool {
        let order: [SkiDifficulty] = [.beginner, .intermediate, .advanced, .expert]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawString = try container.decode(String.self)
        
        switch rawString.lowercased() {
        case "green", "beginner": self = .beginner
        case "blue", "intermediate": self = .intermediate
        case "black", "advanced": self = .advanced
        case "double black", "expert": self = .expert
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid difficulty level: \(rawString)")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
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
    
    init(id: String, name: String, difficulty: SkiDifficulty, status: Status = .open,
         length: Double, verticalDrop: Double, latitude: Double, longitude: Double,
         topLatitude: Double? = nil, topLongitude: Double? = nil,
         bottomLatitude: Double? = nil, bottomLongitude: Double? = nil) {
        self.id = id
        self.name = name
        self.difficulty = difficulty
        self.status = status
        self.length = length
        self.verticalDrop = verticalDrop
        self.latitude = latitude
        self.longitude = longitude
        self.topLatitude = topLatitude ?? latitude
        self.topLongitude = topLongitude ?? longitude
        self.bottomLatitude = bottomLatitude ?? latitude
        self.bottomLongitude = bottomLongitude ?? longitude
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, difficulty, status, length, verticalDrop
        case latitude, longitude
        case topLatitude, topLongitude
        case bottomLatitude, bottomLongitude
    }
    
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
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(status, forKey: .status)
        try container.encode(length, forKey: .length)
        try container.encode(verticalDrop, forKey: .verticalDrop)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(topLatitude, forKey: .topLatitude)
        try container.encode(topLongitude, forKey: .topLongitude)
        try container.encode(bottomLatitude, forKey: .bottomLatitude)
        try container.encode(bottomLongitude, forKey: .bottomLongitude)
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