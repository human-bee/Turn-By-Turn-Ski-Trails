import SwiftUI
import Firebase
import Sentry

@main
struct SkiTrailsApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        do {
            // Validate required environment variables
            try EnvConfig.validateRequiredVariables()
            
            // Configure Firebase
            FirebaseApp.configure()
            
            // Configure Sentry
            SentrySDK.start { options in
                options.dsn = EnvConfig.sentryDsn
                options.debug = EnvConfig.isDevelopment
                
                // Set environment and additional context
                options.environment = EnvConfig.isDevelopment ? "development" : "production"
                options.enableAutoSessionTracking = true
                options.enableSwizzling = true
                
                // Add custom tags
                options.defaultTags = [
                    "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                    "debug_mode": String(EnvConfig.isDebugMode)
                ]
            }
        } catch {
            // Log the error and set it in the app state
            print("Error initializing app: \(error.localizedDescription)")
            appState.error = error
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
} 