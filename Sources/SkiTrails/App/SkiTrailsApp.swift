import SwiftUI
import Firebase
import MapboxMaps

@main
struct SkiTrailsApp: App {
    init() {
        // Configure Mapbox with access token
        ResourceOptionsManager.default.resourceOptions.accessToken = EnvConfig.mapboxAccessToken
        
        // Configure Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppState())
        }
    }
} 