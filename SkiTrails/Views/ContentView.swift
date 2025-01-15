import SwiftUI
import SkiTrailsCore
import MapboxMaps

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var contentViewModel = ContentViewModel()
    @StateObject private var navigationViewModel = NavigationViewModel()
    
    var body: some View {
        ZStack {
            MapView()
                .environmentObject(navigationViewModel)
                .ignoresSafeArea()
            
            if appState.navigationState == .selectingRoute {
                RouteSelectionView()
                    .environmentObject(navigationViewModel)
            } else if appState.navigationState == .navigating {
                ActiveNavigationView()
                    .environmentObject(navigationViewModel)
            }
        }
        .alert("Error", isPresented: $appState.showErrorAlert) {
            Button("OK") {
                appState.clearError()
            }
        } message: {
            Text(appState.errorMessage)
        }
    }
} 