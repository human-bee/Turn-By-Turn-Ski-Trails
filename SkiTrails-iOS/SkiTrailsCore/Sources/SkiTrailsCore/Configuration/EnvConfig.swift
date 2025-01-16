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
    
    public static var weatherUnlockedApiKey: String {
        guard let key = processInfo.environment["WEATHER_UNLOCKED_API_KEY"] else {
            fatalError("WEATHER_UNLOCKED_API_KEY environment variable not set")
        }
        return key
    }
    
    public static var weatherUnlockedAppId: String {
        guard let appId = processInfo.environment["WEATHER_UNLOCKED_APP_ID"] else {
            fatalError("WEATHER_UNLOCKED_APP_ID environment variable not set")
        }
        return appId
    }
    
    public static var liftieApiBaseUrl: String {
        guard let url = processInfo.environment["LIFTIE_API_BASE_URL"] else {
            fatalError("LIFTIE_API_BASE_URL environment variable not set")
        }
        return url
    }
    
    public static var liftieResortList: [String] {
        guard let resorts = processInfo.environment["LIFTIE_RESORT_LIST"] else {
            fatalError("LIFTIE_RESORT_LIST environment variable not set")
        }
        return resorts.components(separatedBy: ",")
    }
    
    public static var preview: Bool {
        processInfo.environment["PREVIEW"] == "true"
    }
} 