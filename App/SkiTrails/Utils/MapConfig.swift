import Foundation

enum MapConfig {
    enum MapConfigError: LocalizedError {
        case missingAccessToken
        
        var errorDescription: String? {
            switch self {
            case .missingAccessToken:
                return "Missing Mapbox access token"
            }
        }
    }
    
    static func getMapboxAccessToken() throws -> String {
        if let token = ProcessInfo.processInfo.environment["MAPBOX_ACCESS_TOKEN"] {
            return token
        }
        if let token = Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAccessToken") as? String {
            return token
        }
        throw MapConfigError.missingAccessToken
    }
} 