import Foundation
import CoreLocation
import Sentry

/// A service that handles error reporting and user-facing error messages
actor ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    // MARK: - Error Handling
    
    func handle(_ error: Error, context: ErrorContext? = nil) {
        // Log the error
        print("Error: \(error.localizedDescription)")
        
        // Report to Sentry if in production
        if !EnvConfig.isDevelopment {
            let scope = Scope()
            if let context = context {
                scope.setContext(value: context.contextData, key: context.name)
            }
            SentrySDK.capture(error: error, scope: scope)
        }
    }
    
    func handleUserFacing(_ error: Error, context: ErrorContext? = nil) -> UserFacingError {
        // Handle the error
        handle(error, context: context)
        
        // Convert to user-facing error
        switch error {
        case let apiError as APIError:
            return .init(
                title: "API Error",
                message: apiError.localizedDescription,
                recoverySuggestion: apiError.recoverySuggestion
            )
        case let routingError as RoutingError:
            return .init(
                title: "Navigation Error",
                message: routingError.localizedDescription,
                recoverySuggestion: routingError.recoverySuggestion
            )
        case let envError as EnvConfigError:
            return .init(
                title: "Configuration Error",
                message: envError.localizedDescription,
                recoverySuggestion: "Please ensure all required environment variables are set."
            )
        default:
            return .init(
                title: "Error",
                message: error.localizedDescription,
                recoverySuggestion: "Please try again later."
            )
        }
    }
}

// MARK: - Supporting Types

/// Represents an error that can be shown to users
struct UserFacingError: LocalizedError {
    let title: String
    let message: String
    let recoverySuggestion: String?
    
    var errorDescription: String? { message }
}

/// Context information for error reporting
struct ErrorContext {
    let name: String
    let contextData: [String: Any]
    
    static func api(endpoint: String, parameters: [String: Any] = [:]) -> ErrorContext {
        ErrorContext(
            name: "api_call",
            contextData: [
                "endpoint": endpoint,
                "parameters": parameters
            ]
        )
    }
    
    static func navigation(
        startPoint: CLLocationCoordinate2D,
        endPoint: CLLocationCoordinate2D,
        difficulty: SkiDifficulty
    ) -> ErrorContext {
        ErrorContext(
            name: "navigation",
            contextData: [
                "start_latitude": startPoint.latitude,
                "start_longitude": startPoint.longitude,
                "end_latitude": endPoint.latitude,
                "end_longitude": endPoint.longitude,
                "difficulty": difficulty.rawValue
            ]
        )
    }
}

// MARK: - Error Extensions

extension APIError {
    var recoverySuggestion: String? {
        switch self {
        case .unauthorized:
            return "Please check your API keys and try again."
        case .networkError:
            return "Please check your internet connection and try again."
        case .serverError:
            return "The server is experiencing issues. Please try again later."
        default:
            return nil
        }
    }
}

extension RoutingError {
    var recoverySuggestion: String? {
        switch self {
        case .graphNotInitialized:
            return "Please wait for resort data to load and try again."
        case .noRouteFound:
            return "Try selecting different start/end points or adjusting difficulty settings."
        case .invalidPath:
            return "The selected route is no longer available. Please try a different route."
        }
    }
} 