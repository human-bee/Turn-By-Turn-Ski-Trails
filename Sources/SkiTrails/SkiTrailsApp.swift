import SwiftUI
import SkiTrailsCore

@main
struct SkiTrailsApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
} 