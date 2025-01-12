import SwiftUI
import SkiTrailsCore

struct RouteSelectionView: View {
    let resort: Resort
    @ObservedObject var viewModel: NavigationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Start Point") {
                    Picker("Select Start Point", selection: $viewModel.startPoint) {
                        Text("Current Location").tag(nil as Run?)
                        ForEach(resort.runs) { run in
                            Text(run.name).tag(run as Run?)
                        }
                    }
                }
                
                Section("End Point") {
                    Picker("Select End Point", selection: $viewModel.endPoint) {
                        ForEach(resort.runs) { run in
                            Text(run.name).tag(run as Run?)
                        }
                    }
                }
                
                Section {
                    Button("Start Navigation") {
                        Task {
                            await viewModel.startNavigation()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canStartNavigation)
                }
            }
            .navigationTitle("Select Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let appState = AppState()
    let resort = Resort.preview
    return RouteSelectionView(
        resort: resort,
        viewModel: NavigationViewModel(appState: appState)
    )
    .environmentObject(appState)
} 