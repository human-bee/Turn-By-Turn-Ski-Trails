import SwiftUI
import Firebase
import Sentry

@main
struct SkiTrailsApp: App {
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Initialize Sentry
        SentrySDK.start { options in
            options.dsn = ProcessInfo.processInfo.environment["SENTRY_DSN"] ?? ""
            options.debug = true
            options.enableAutoSessionTracking = true
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
} 