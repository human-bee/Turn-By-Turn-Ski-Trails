import Foundation

public struct EntityID: Codable, Hashable, Identifiable {
    public let rawValue: String
    public var id: String { rawValue }
    
    public init(_ uuid: UUID) {
        self.rawValue = uuid.uuidString
    }
    
    public init(_ string: String) {
        self.rawValue = string
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self.rawValue = value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct Resort: Identifiable, Codable {
    public let id: EntityID
    public let name: String
    public let lifts: [Lift]
    public let runs: [Run]
    
    public init(id: EntityID, name: String, lifts: [Lift], runs: [Run]) {
        self.id = id
        self.name = name
        self.lifts = lifts
        self.runs = runs
    }
    
    public static var preview: Resort {
        let lifts = [
            Lift(
                id: EntityID(UUID()),
                name: "Express Lift",
                status: .open,
                startLocation: Location(latitude: 39.6450, longitude: -106.3750, altitude: 3000),
                endLocation: Location(latitude: 39.6500, longitude: -106.3800, altitude: 3500),
                capacity: 6,
                waitTime: 600
            )
        ]
        
        let runs = [
            Run(
                id: EntityID(UUID()),
                name: "Easy Street",
                difficulty: .beginner,
                status: .open,
                startLocation: Location(latitude: 39.6450, longitude: -106.3750, altitude: 3000),
                endLocation: Location(latitude: 39.6403, longitude: -106.3742, altitude: 2500),
                length: 1000,
                verticalDrop: 500
            ),
            Run(
                id: EntityID(UUID()),
                name: "Blue Heaven",
                difficulty: .intermediate,
                status: .open,
                startLocation: Location(latitude: 39.6500, longitude: -106.3800, altitude: 3500),
                endLocation: Location(latitude: 39.6450, longitude: -106.3750, altitude: 3000),
                length: 1500,
                verticalDrop: 500
            )
        ]
        
        return Resort(
            id: EntityID(UUID()),
            name: "Test Resort",
            lifts: lifts,
            runs: runs
        )
    }
}

public struct Lift: Identifiable, Codable {
    public let id: EntityID
    public let name: String
    public let status: Status
    public let startLocation: Location
    public let endLocation: Location
    public let capacity: Int
    public let waitTime: TimeInterval?
    
    public enum Status: String, Codable {
        case open, closed, onHold, maintenance
    }
    
    public init(id: EntityID, name: String, status: Status, startLocation: Location, endLocation: Location, capacity: Int, waitTime: TimeInterval? = nil) {
        self.id = id
        self.name = name
        self.status = status
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.capacity = capacity
        self.waitTime = waitTime
    }
}

public struct Run: Identifiable, Codable, Hashable {
    public let id: EntityID
    public let name: String
    public let difficulty: Difficulty
    public let status: Status
    public let startLocation: Location
    public let endLocation: Location
    public let length: Double
    public let verticalDrop: Double
    
    public enum Difficulty: String, Codable, CaseIterable, Comparable {
        case beginner, intermediate, advanced, expert
        
        public static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
            let order: [Difficulty] = [.beginner, .intermediate, .advanced, .expert]
            guard let lhsIndex = order.firstIndex(of: lhs),
                  let rhsIndex = order.firstIndex(of: rhs) else {
                return false
            }
            return lhsIndex < rhsIndex
        }
        
        public var color: String {
            switch self {
            case .beginner: return "green"
            case .intermediate: return "blue"
            case .advanced: return "black"
            case .expert: return "doubleBlack"
            }
        }
    }
    
    public enum Status: String, Codable {
        case open, closed, grooming
    }
    
    public init(id: EntityID, name: String, difficulty: Difficulty, status: Status, startLocation: Location, endLocation: Location, length: Double, verticalDrop: Double) {
        self.id = id
        self.name = name
        self.difficulty = difficulty
        self.status = status
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.length = length
        self.verticalDrop = verticalDrop
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Run, rhs: Run) -> Bool {
        lhs.id == rhs.id
    }
}

public struct Location: Equatable, Hashable, Codable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double
    
    public init(latitude: Double, longitude: Double, altitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
    }
}

public struct Weather: Codable {
    public let temperature: Double
    public let conditions: String
    public let snowDepth: Double
    public let windSpeed: Double
    public let visibility: Double
    
    public init(temperature: Double, conditions: String, snowDepth: Double, windSpeed: Double, visibility: Double) {
        self.temperature = temperature
        self.conditions = conditions
        self.snowDepth = snowDepth
        self.windSpeed = windSpeed
        self.visibility = visibility
    }
} 