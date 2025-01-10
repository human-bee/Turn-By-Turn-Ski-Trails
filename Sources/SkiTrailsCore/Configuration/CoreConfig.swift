import Foundation
import SwiftUI

// MARK: - Core Configuration
public enum CoreConfig {
    public enum Error: Swift.Error, LocalizedError {
        case fileNotFound(String)
        case invalidFormat
        case missingKey(String)
        
        public var errorDescription: String? {
            switch self {
            case .fileNotFound(let path):
                return "Configuration file not found at: \(path)"
            case .invalidFormat:
                return "Invalid configuration file format"
            case .missingKey(let key):
                return "Missing required configuration key: \(key)"
            }
        }
    }
    
    private static var envVariables: [String: String]?
    
    private static func loadEnvironmentVariables() throws -> [String: String] {
        if let loaded = envVariables {
            return loaded
        }
        
        guard let filePath = Bundle.main.path(forResource: ".env", ofType: nil) else {
            throw Error.fileNotFound(".env")
        }
        
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        var variables: [String: String] = [:]
        
        content.components(separatedBy: .newlines).forEach { line in
            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                if !key.hasPrefix("#") && !value.isEmpty {
                    variables[key] = value
                }
            }
        }
        
        envVariables = variables
        return variables
    }
    
    public static func getValue(for key: String) throws -> String {
        let variables = try loadEnvironmentVariables()
        guard let value = variables[key] else {
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
        let resortString = try getValue(for: "LIFTIE_RESORT_LIST")
        return resortString.split(separator: ",").map(String.init)
    }
    
    public static func getAPIBaseURL() throws -> URL {
        let urlString = try getValue(for: "API_BASE_URL")
        guard let url = URL(string: urlString) else {
            throw Error.invalidFormat
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