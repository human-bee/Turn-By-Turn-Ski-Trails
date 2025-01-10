import SwiftUI
import Firebase
import Sentry
import SkiTrailsCore

@main
struct SkiTrailsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Try to initialize Firebase if configuration exists
        if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            FirebaseApp.configure()
        } else {
            print("Warning: GoogleService-Info.plist not found. Firebase features will be disabled.")
        }
        
        // Initialize Sentry
        SentrySDK.start { options in
            options.dsn = ProcessInfo.processInfo.environment["SENTRY_DSN"] ?? ""
            options.debug = true
            options.enableAutoSessionTracking = true
        }
        
        return true
    }
} 