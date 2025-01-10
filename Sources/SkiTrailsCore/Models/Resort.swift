import Foundation

public struct Resort: Identifiable {
    public let id: UUID
    public let name: String
    public var lifts: [Lift]
    public var runs: [Run]
    public var weather: WeatherInfo?
    
    public init(id: UUID = UUID(), name: String, lifts: [Lift] = [], runs: [Run] = [], weather: WeatherInfo? = nil) {
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
    public var status: Status
    public let bottomLocation: Location
    public let topLocation: Location
    
    public enum Status: String {
        case open
        case closed
        case hold
        case scheduled
    }
}

public struct Run: Identifiable {
    public let id: UUID
    public let name: String
    public let difficulty: Difficulty
    public var status: Status
    public let path: [Location]
    
    public enum Status: String {
        case open
        case closed
        case grooming
    }
    
    public enum Difficulty: String {
        case beginner
        case intermediate
        case advanced
        case expert
    }
}

public struct Location {
    public let latitude: Double
    public let longitude: Double
    public let elevation: Double
    
    public init(latitude: Double, longitude: Double, elevation: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
    }
}

public struct WeatherInfo {
    public let temperature: Double
    public let conditions: String
    public let windSpeed: Double
    public let snowDepth: Double
    
    public init(temperature: Double, conditions: String, windSpeed: Double, snowDepth: Double) {
        self.temperature = temperature
        self.conditions = conditions
        self.windSpeed = windSpeed
        self.snowDepth = snowDepth
    }
} 