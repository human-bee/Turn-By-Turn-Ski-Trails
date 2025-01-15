import SwiftUI
import SkiTrailsCore

class AppState: ObservableObject {
    @Published var selectedResort: Resort?
    @Published var navigationState: NavigationState = .idle
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""
    
    enum NavigationState {
        case idle
        case selectingRoute
        case navigating
    }
    
    func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    func clearError() {
        errorMessage = ""
        showErrorAlert = false
    }
} 