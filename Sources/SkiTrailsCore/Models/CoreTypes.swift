import Foundation
import SwiftUI

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
    
    public static func getDSN() throws -> String {
        guard let filePath = Bundle.main.path(forResource: ".env", ofType: nil) else {
            throw Error.fileNotFound(".env")
        }
        
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2 && parts[0].trimmingCharacters(in: .whitespaces) == "SENTRY_DSN" {
                let dsn = parts[1].trimmingCharacters(in: .whitespaces)
                if !dsn.isEmpty {
                    return dsn
                }
            }
        }
        
        throw Error.missingKey("SENTRY_DSN")
    }
} 