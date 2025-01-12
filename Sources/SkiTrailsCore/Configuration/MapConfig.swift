import Foundation

public enum MapConfig {
    public enum Error: Swift.Error, LocalizedError {
        case missingMapboxToken
        
        public var errorDescription: String? {
            switch self {
            case .missingMapboxToken:
                return "Missing Mapbox access token"
            }
        }
    }
    
    public static func getMapboxAccessToken() throws -> String {
        try CoreConfig.getMapboxAccessToken()
    }
} 