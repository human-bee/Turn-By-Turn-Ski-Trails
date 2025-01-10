import Foundation

enum MapConfig {
    enum MapConfigError: LocalizedError {
        case missingAccessToken
        
        var errorDescription: String? {
            switch self {
            case .missingAccessToken:
                return "Mapbox access token not found. Please set MAPBOX_ACCESS_TOKEN in your environment or Info.plist."
            }
        }
    }
    
    static func getMapboxAccessToken() throws -> String {
        // First try environment variable
        if let token = ProcessInfo.processInfo.environment["MAPBOX_ACCESS_TOKEN"] {
            return token
        }
        
        // Then try Info.plist
        if let token = Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAccessToken") as? String {
            return token
        }
        
        throw MapConfigError.missingAccessToken
    }
} 