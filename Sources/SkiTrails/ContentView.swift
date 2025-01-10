import SwiftUI
import SkiTrailsCore

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Text("Ski Trails")
            .padding()
            .overlay {
                if appState.isLoading {
                    ProgressView()
                }
            }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}