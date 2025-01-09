import Foundation

/// A utility struct that provides type-safe access to environment variables
enum EnvConfig {
    // MARK: - Map Rendering
    static var mapboxAccessToken: String {
        ProcessInfo.processInfo.environment["MAPBOX_ACCESS_TOKEN"] ?? ""
    }
    
    // MARK: - Weather and Snow Data
    static var weatherUnlockedApiKey: String {
        ProcessInfo.processInfo.environment["WEATHER_UNLOCKED_API_KEY"] ?? ""
    }
    
    static var weatherUnlockedAppId: String {
        ProcessInfo.processInfo.environment["WEATHER_UNLOCKED_APP_ID"] ?? ""
    }
    
    static var skiApiKey: String {
        ProcessInfo.processInfo.environment["SKI_API_KEY"] ?? ""
    }
    
    // MARK: - Liftie API
    static var liftieApiBaseUrl: String {
        ProcessInfo.processInfo.environment["LIFTIE_API_BASE_URL"] ?? "https://liftie.info/api/resort"
    }
    
    static var liftieRefreshInterval: TimeInterval {
        Double(ProcessInfo.processInfo.environment["LIFTIE_REFRESH_INTERVAL"] ?? "65000") ?? 65000
    }
    
    static var liftieResortList: [String] {
        let list = ProcessInfo.processInfo.environment["LIFTIE_RESORT_LIST"] ?? ""
        return list.split(separator: ",").map(String.init)
    }
    
    // MARK: - Ski Resorts Information
    static var skiResortsInformationApiKey: String {
        ProcessInfo.processInfo.environment["SKI_RESORTS_INFORMATION_API_KEY"] ?? ""
    }
    
    // MARK: - Navigation and Routing
    static var navigationApiKey: String {
        ProcessInfo.processInfo.environment["NAVIGATION_API_KEY"] ?? ""
    }
    
    static var graphqlEndpoint: String {
        ProcessInfo.processInfo.environment["GRAPHQL_ENDPOINT"] ?? ""
    }
    
    static var graphqlAuthToken: String {
        ProcessInfo.processInfo.environment["GRAPHQL_AUTH_TOKEN"] ?? ""
    }
    
    // MARK: - Backend Configuration
    static var apiBaseUrl: String {
        ProcessInfo.processInfo.environment["API_BASE_URL"] ?? ""
    }
    
    static var apiAuthToken: String {
        ProcessInfo.processInfo.environment["API_AUTH_TOKEN"] ?? ""
    }
    
    // MARK: - Real-Time Updates
    static var realtimeApiUrl: String {
        ProcessInfo.processInfo.environment["REALTIME_API_URL"] ?? ""
    }
    
    static var realtimeApiKey: String {
        ProcessInfo.processInfo.environment["REALTIME_API_KEY"] ?? ""
    }
    
    // MARK: - App Configuration
    static var isDebugMode: Bool {
        ProcessInfo.processInfo.environment["DEBUG_MODE"]?.lowercased() == "true"
    }
    
    static var isDevelopment: Bool {
        ProcessInfo.processInfo.environment["APP_ENV"]?.lowercased() == "development"
    }
    
    // MARK: - Firebase
    static var firebaseApiKey: String {
        ProcessInfo.processInfo.environment["FIREBASE_API_KEY"] ?? ""
    }
    
    static var firebaseProjectId: String {
        ProcessInfo.processInfo.environment["FIREBASE_PROJECT_ID"] ?? ""
    }
    
    static var firebaseMessagingSenderId: String {
        ProcessInfo.processInfo.environment["FIREBASE_MESSAGING_SENDER_ID"] ?? ""
    }
    
    static var firebaseAppId: String {
        ProcessInfo.processInfo.environment["FIREBASE_APP_ID"] ?? ""
    }
    
    // MARK: - Analytics and Logging
    static var googleAnalyticsKey: String {
        ProcessInfo.processInfo.environment["GOOGLE_ANALYTICS_KEY"] ?? ""
    }
    
    static var sentryDsn: String {
        ProcessInfo.processInfo.environment["SENTRY_DSN"] ?? ""
    }
    
    // MARK: - Custom Configuration
    static var custom3dModelUrl: String {
        ProcessInfo.processInfo.environment["CUSTOM_3D_MODEL_URL"] ?? ""
    }
    
    // MARK: - Validation
    
    /// Validates that all required environment variables are present
    static func validateRequiredVariables() throws {
        let requiredVariables = [
            ("MAPBOX_ACCESS_TOKEN", mapboxAccessToken),
            ("WEATHER_UNLOCKED_API_KEY", weatherUnlockedApiKey),
            ("WEATHER_UNLOCKED_APP_ID", weatherUnlockedAppId),
            ("SKI_API_KEY", skiApiKey)
        ]
        
        let missingVariables = requiredVariables
            .filter { $0.1.isEmpty }
            .map { $0.0 }
        
        guard missingVariables.isEmpty else {
            throw EnvConfigError.missingRequiredVariables(missingVariables)
        }
    }
}

// MARK: - Error Types

enum EnvConfigError: LocalizedError {
    case missingRequiredVariables([String])
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredVariables(let variables):
            return "Missing required environment variables: \(variables.joined(separator: ", "))"
        }
    }
} 