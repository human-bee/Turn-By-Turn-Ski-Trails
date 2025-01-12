import Foundation
import SwiftUI

// MARK: - Core Configuration
public enum CoreConfig {
    public enum Error: Swift.Error, LocalizedError {
        case missingKey(String)
        case invalidURLFormat(String)
        
        public var errorDescription: String? {
            switch self {
            case .missingKey(let key):
                return "Missing required environment variable: \(key)"
            case .invalidURLFormat(let url):
                return "Invalid URL format: \(url)"
            }
        }
    }
    
    public static func getValue(for key: String) throws -> String {
        guard let value = ProcessInfo.processInfo.environment[key], !value.isEmpty else {
            throw Error.missingKey(key)
        }
        return value
    }
    
    public static func getDSN() throws -> String {
        try getValue(for: "SENTRY_DSN")
    }
    
    public static func getMapboxAccessToken() throws -> String {
        try getValue(for: "MAPBOX_ACCESS_TOKEN")
    }
    
    public static func getWeatherAPIKey() throws -> String {
        try getValue(for: "WEATHER_UNLOCKED_API_KEY")
    }
    
    public static func getWeatherAppID() throws -> String {
        try getValue(for: "WEATHER_UNLOCKED_APP_ID")
    }
    
    public static func getLiftieAPIBaseURL() throws -> String {
        try getValue(for: "LIFTIE_API_BASE_URL")
    }
    
    public static func getLiftieResortList() throws -> [String] {
        let list = try getValue(for: "LIFTIE_RESORT_LIST")
        return list.split(separator: ",").map(String.init)
    }
    
    public static func getAPIBaseURL() throws -> URL {
        let urlString = try getValue(for: "API_BASE_URL")
        guard let url = URL(string: urlString) else {
            throw Error.invalidURLFormat(urlString)
        }
        return url
    }
}

// MARK: - Core State Management
public protocol CoreStateManaging: ObservableObject {
    var selectedResort: Resort? { get }
    var isLoading: Bool { get }
    var error: Error? { get }
    
    func selectResort(_ resort: Resort)
    func setError(_ error: Error)
    func setLoading(_ loading: Bool)
}

public final class CoreState: CoreStateManaging {
    @Published public private(set) var selectedResort: Resort?
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    
    public init() {}
    
    public func selectResort(_ resort: Resort) {
        selectedResort = resort
    }
    
    public func setError(_ error: Error) {
        self.error = error
    }
    
    public func setLoading(_ loading: Bool) {
        isLoading = loading
    }
} 