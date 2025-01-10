import Foundation

public struct Resort: Identifiable {
    public let id: UUID
    public let name: String
    public let lifts: [Lift]
    public let runs: [Run]
    public var weather: Weather?
    
    public init(id: UUID = UUID(), name: String, lifts: [Lift], runs: [Run], weather: Weather? = nil) {
        self.id = id
        self.name = name
        self.lifts = lifts
        self.runs = runs
        self.weather = weather
    }
}

public struct Lift: Identifiable {
    public let id: UUID
    public let name: String
    public let status: Status
    public let startLocation: Location
    public let endLocation: Location
    public let capacity: Int
    public let waitTime: TimeInterval?
    
    public init(id: UUID = UUID(), name: String, status: Status = .open, startLocation: Location, endLocation: Location, capacity: Int, waitTime: TimeInterval? = nil) {
        self.id = id
        self.name = name
        self.status = status
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.capacity = capacity
        self.waitTime = waitTime
    }
    
    public enum Status: String {
        case open
        case closed
        case onHold
        case maintenance
    }
}

public struct Run: Identifiable {
    public let id: UUID
    public let name: String
    public let difficulty: Difficulty
    public let status: Status
    public let startLocation: Location
    public let endLocation: Location
    public let length: Double // in meters
    public let verticalDrop: Double // in meters
    
    public init(id: UUID = UUID(), name: String, difficulty: Difficulty, status: Status = .open, startLocation: Location, endLocation: Location, length: Double, verticalDrop: Double) {
        self.id = id
        self.name = name
        self.difficulty = difficulty
        self.status = status
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.length = length
        self.verticalDrop = verticalDrop
    }
    
    public enum Difficulty: String, CaseIterable {
        case beginner
        case intermediate
        case advanced
        case expert
        
        public var color: String {
            switch self {
            case .beginner: return "green"
            case .intermediate: return "blue"
            case .advanced: return "black"
            case .expert: return "doubleBlack"
            }
        }
    }
    
    public enum Status: String {
        case open
        case closed
        case grooming
    }
}

public struct Location: Equatable, Hashable {
    public let latitude: Double
    public let longitude: Double
    public let elevation: Double // in meters
    
    public init(latitude: Double, longitude: Double, elevation: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
    }
    
    public func distance(to other: Location) -> Double {
        // Basic Euclidean distance calculation - could be enhanced with actual terrain consideration
        let latDiff = latitude - other.latitude
        let lonDiff = longitude - other.longitude
        let elevDiff = elevation - other.elevation
        return sqrt(pow(latDiff, 2) + pow(lonDiff, 2) + pow(elevDiff, 2))
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
        hasher.combine(elevation)
    }
}

public struct Weather {
    public let temperature: Double // in Fahrenheit
    public let conditions: String
    public let windSpeed: Double // in mph
    public let visibility: Double // in miles
    public let snowfall: Double? // in inches (last 24 hours)
    
    public init(temperature: Double, conditions: String, windSpeed: Double, visibility: Double, snowfall: Double? = nil) {
        self.temperature = temperature
        self.conditions = conditions
        self.windSpeed = windSpeed
        self.visibility = visibility
        self.snowfall = snowfall
    }
} 