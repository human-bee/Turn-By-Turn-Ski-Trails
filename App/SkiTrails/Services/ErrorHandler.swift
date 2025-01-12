import Foundation
import CoreLocation
import Sentry
import SkiTrailsCore

/// A service that handles error reporting and user-facing error messages
actor ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    // MARK: - Error Handling
    
    func handle(_ error: Error, context: ErrorContext? = nil) {
        // Only send to Sentry in non-development environments
        if !EnvConfig.isDevelopment {
            let event = Event(level: .error)
            event.message = SentryMessage(formatted: error.localizedDescription)
            
            if let context = context {
                event.extra = context.contextData
                event.tags = ["context": context.name]
            }
            
            SentrySDK.capture(event: event)
        }
        
        // Log locally in debug mode
        #if DEBUG
        print("Error: \(error.localizedDescription)")
        if let context = context {
            print("Context: \(context.name)")
            print("Data: \(context.contextData)")
        }
        #endif
    }
    
    func handleUserFacing(_ error: Error, context: ErrorContext? = nil) -> UserFacingError {
        // Log the error
        handle(error, context: context)
        
        // Convert to user-facing error
        switch error {
        case let apiError as APIError:
            return UserFacingError(
                title: "Connection Error",
                message: apiError.localizedDescription,
                recoverySuggestion: apiError.recoverySuggestion
            )
        case let routingError as RoutingError:
            return UserFacingError(
                title: "Navigation Error",
                message: routingError.localizedDescription,
                recoverySuggestion: routingError.recoverySuggestion
            )
        case let locationError as CLError:
            return UserFacingError(
                title: "Location Error",
                message: locationError.localizedDescription,
                recoverySuggestion: "Please check your location permissions and try again."
            )
        default:
            return UserFacingError(
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
            name: "API Error",
            contextData: [
                "endpoint": endpoint,
                "parameters": parameters
            ]
        )
    }
    
    static func navigation(
        start: CLLocationCoordinate2D,
        end: CLLocationCoordinate2D,
        preferences: RoutePreferences
    ) -> ErrorContext {
        ErrorContext(
            name: "Navigation Error",
            contextData: [
                "start": "\(start.latitude),\(start.longitude)",
                "end": "\(end.latitude),\(end.longitude)",
                "preferences": [
                    "avoidCrowds": preferences.avoidCrowds,
                    "preferLessStrenuous": preferences.preferLessStrenuous,
                    "maxWaitTime": preferences.maxWaitTime as Any
                ]
            ]
        )
    }
}

// MARK: - Error Extensions

extension APIError {
    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Please check your internet connection and try again."
        case .invalidResponse:
            return "The server returned an invalid response. Please try again later."
        case .networkError:
            return "Please check your internet connection and try again."
        case .decodingError:
            return "There was a problem processing the server response. Please try again later."
        case .serverError:
            return "The server is experiencing issues. Please try again later."
        case .unauthorized:
            return "Please sign in again to continue."
        case .unknown:
            return "Please try again later."
        }
    }
}

extension RoutingError {
    var recoverySuggestion: String? {
        switch self {
        case .graphNotInitialized:
            return "Please wait for the resort data to load and try again."
        case .noRouteFound:
            return "Try selecting different start and end points, or adjust your difficulty preferences."
        case .invalidPath:
            return "The selected route is no longer valid. Please try a different route."
        }
    }
} 