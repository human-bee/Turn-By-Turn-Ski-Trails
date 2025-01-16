import Foundation

public struct UserFacingError: LocalizedError {
    public let title: String
    public let message: String
    
    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }
    
    public var errorDescription: String? {
        message
    }
}

extension UserFacingError {
    public static let noCurrentLocation = UserFacingError(
        title: "Location Not Available",
        message: "Unable to determine your current location. Please ensure location services are enabled."
    )
    
    public static let navigationError = UserFacingError(
        title: "Navigation Error",
        message: "Unable to calculate a route to your destination. Please try again."
    )
    
    public static let resortLoadError = UserFacingError(
        title: "Resort Load Error",
        message: "Unable to load resort data. Please check your connection and try again."
    )
} 