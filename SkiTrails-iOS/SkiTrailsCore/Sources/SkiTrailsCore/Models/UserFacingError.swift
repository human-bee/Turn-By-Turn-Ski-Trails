import Foundation

public struct UserFacingError: LocalizedError {
    public let title: String
    public let message: String
    public let recoverySuggestion: String?
    
    public init(title: String, message: String, recoverySuggestion: String? = nil) {
        self.title = title
        self.message = message
        self.recoverySuggestion = recoverySuggestion
    }
    
    public var errorDescription: String? {
        message
    }
}

extension UserFacingError {
    public static let noCurrentLocation = UserFacingError(
        title: "Location Not Available",
        message: "Unable to determine your current location. Please ensure location services are enabled.",
        recoverySuggestion: "Check if location services are enabled in your device settings."
    )
    
    public static let navigationError = UserFacingError(
        title: "Navigation Error",
        message: "Unable to calculate a route to your destination. Please try again.",
        recoverySuggestion: "Make sure both start and end points are accessible."
    )
    
    public static let resortLoadError = UserFacingError(
        title: "Resort Load Error",
        message: "Unable to load resort data. Please check your connection and try again.",
        recoverySuggestion: "Check your internet connection and try again."
    )
} 