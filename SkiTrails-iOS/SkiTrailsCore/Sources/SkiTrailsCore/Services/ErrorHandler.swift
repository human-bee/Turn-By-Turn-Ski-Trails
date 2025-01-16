import Foundation

public class ErrorHandler {
    public static let shared = ErrorHandler()
    
    private init() {}
    
    @MainActor
    public func handle(_ error: Error) async {
        if let appState = try? await AppState.shared {
            appState.error = error
        }
    }
    
    public func convertToUserFacing(_ error: Error) -> UserFacingError {
        if let userFacing = error as? UserFacingError {
            return userFacing
        }
        
        return UserFacingError(
            title: "Error",
            message: error.localizedDescription
        )
    }
} 