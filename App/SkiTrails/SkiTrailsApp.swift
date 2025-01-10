import SwiftUI
import Sentry
import SkiTrailsCore

@main
struct SkiTrailsApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        // Initialize Sentry
        do {
            let dsn = try CoreConfig.getDSN()
            SentrySDK.start { options in
                options.dsn = dsn
                options.debug = true
                options.tracesSampleRate = 1.0
                options.enableSwizzling = true
            }
        } catch let error as CoreConfig.Error {
            switch error {
            case .fileNotFound(let path):
                print("Failed to initialize Sentry: .env file not found at \(path)")
            case .invalidFormat:
                print("Failed to initialize Sentry: Invalid .env file format")
            case .missingKey(let key):
                print("Failed to initialize Sentry: Missing key \(key) in .env file")
            }
        } catch {
            print("Failed to initialize Sentry: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
} 