import Foundation

public enum MapConfig {
    public enum Error: Swift.Error, LocalizedError {
        case missingMapboxToken
        
        public var errorDescription: String? {
            switch self {
            case .missingMapboxToken:
                return "Mapbox access token not found in environment configuration"
            }
        }
    }
    
    public static func getMapboxAccessToken() throws -> String {
        try CoreConfig.getMapboxAccessToken()
    }
} 