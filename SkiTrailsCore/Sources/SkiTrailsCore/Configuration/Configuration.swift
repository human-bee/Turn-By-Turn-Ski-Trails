import Foundation

public struct Configuration {
    public let apiBaseURL: URL
    public let apiKey: String
    
    public init() throws {
        self.apiBaseURL = try CoreConfig.getAPIBaseURL()
        self.apiKey = try CoreConfig.getValue(for: "API_AUTH_TOKEN")
    }
    
    public static func `default`() throws -> Configuration {
        try Configuration()
    }
}

extension Configuration {
    public enum Error: Swift.Error, LocalizedError {
        case invalidURL
        case missingAPIKey
        
        public var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid API base URL format"
            case .missingAPIKey:
                return "Missing API authentication key"
            }
        }
    }
} 