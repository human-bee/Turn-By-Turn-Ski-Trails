import Foundation

public enum EnvConfig {
    private static let processInfo = ProcessInfo.processInfo
    
    public static var mapboxAccessToken: String {
        guard let token = processInfo.environment["MAPBOX_ACCESS_TOKEN"] else {
            fatalError("MAPBOX_ACCESS_TOKEN environment variable not set")
        }
        return token
    }
    
    public static var apiBaseURL: String {
        guard let url = processInfo.environment["API_BASE_URL"] else {
            fatalError("API_BASE_URL environment variable not set")
        }
        return url
    }
    
    public static var preview: Bool {
        processInfo.environment["PREVIEW"] == "true"
    }
} 