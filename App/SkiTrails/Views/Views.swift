import SwiftUI
import MapKit
import SkiTrailsCore

// MARK: - Common Views
struct DifficultyIndicator: View {
    let difficulty: Run.Difficulty
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(difficulty.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var color: Color {
        switch difficulty {
        case .beginner:
            return .green
        case .intermediate:
            return .blue
        case .advanced:
            return .black
        case .expert:
            return .red
        }
    }
}

struct StatusBadge: View {
    let status: String
    let color: Color
    
    init(liftStatus: Lift.Status) {
        self.status = liftStatus.rawValue.capitalized
        switch liftStatus {
        case .open:
            self.color = .green
        case .closed:
            self.color = .red
        case .hold:
            self.color = .orange
        case .scheduled:
            self.color = .blue
        case .grooming:
            self.color = .purple
        }
    }
    
    init(runStatus: Run.Status) {
        self.status = runStatus.rawValue.capitalized
        switch runStatus {
        case .open:
            self.color = .green
        case .closed:
            self.color = .red
        case .hold:
            self.color = .orange
        case .scheduled:
            self.color = .blue
        case .grooming:
            self.color = .purple
        }
    }
    
    var body: some View {
        Text(status)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

struct LiftStatusRow: View {
    let lift: Lift
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(lift.name)
                    .font(.headline)
                
                if let waitTime = lift.waitTime {
                    Text("\(Int(waitTime / 60)) min wait")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            StatusBadge(liftStatus: lift.status)
        }
        .padding(.vertical, 4)
    }
}

struct RunStatusRow: View {
    let run: Run
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(run.name)
                    .font(.headline)
                
                DifficultyIndicator(difficulty: run.difficulty)
            }
            
            Spacer()
            
            StatusBadge(runStatus: run.status)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Content View
struct ContentView: View {
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ResortListView()
                .tabItem {
                    Label("Resorts", systemImage: "list.bullet")
                }
                .tag(0)
            
            SkiMapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(1)
            
            TrailStatusView()
                .tabItem {
                    Label("Status", systemImage: "info.circle")
                }
                .tag(2)
            
            NavigationSetupView()
                .tabItem {
                    Label("Navigate", systemImage: "location.fill")
                }
                .tag(3)
            
            ARResortView()
                .tabItem {
                    Label("AR View", systemImage: "camera.fill")
                }
                .tag(4)
        }
        .environmentObject(appState)
    }
}

// MARK: - Resort List View
struct ResortListView: View {
    @StateObject private var viewModel = ResortViewModel()
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    List(appState.resorts) { resort in
                        ResortRowView(resort: resort)
                            .onTapGesture {
                                viewModel.selectResort(resort)
                            }
                    }
                }
            }
            .navigationTitle("Ski Resorts")
            .task {
                await appState.loadResorts()
            }
            .onAppear {
                viewModel.onAppear()
            }
            .onDisappear {
                viewModel.onDisappear()
            }
        }
    }
}

// MARK: - Trail Status View
struct TrailStatusView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ResortViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let resort = appState.selectedResort {
                    List {
                        Section("Lifts") {
                            ForEach(resort.lifts) { lift in
                                LiftStatusRow(lift: lift)
                            }
                        }
                        
                        Section("Runs") {
                            ForEach(resort.runs) { run in
                                RunStatusRow(run: run)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Resort Selected",
                        systemImage: "mountain.2",
                        description: Text("Select a resort to view trail status")
                    )
                }
            }
            .navigationTitle("Trail Status")
            .refreshable {
                if let resort = appState.selectedResort {
                    await viewModel.refresh(resort)
                }
            }
        }
    }
}

// MARK: - Navigation Setup View
struct NavigationSetupView: View {
    @StateObject private var viewModel: NavigationViewModel
    @EnvironmentObject private var appState: AppState
    
    init() {
        _viewModel = StateObject(wrappedValue: NavigationViewModel(appState: appState))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Skill Level") {
                    Picker("Your Skill Level", selection: $viewModel.skillLevel) {
                        Text("Beginner").tag(Run.Difficulty.beginner)
                        Text("Intermediate").tag(Run.Difficulty.intermediate)
                        Text("Advanced").tag(Run.Difficulty.advanced)
                        Text("Expert").tag(Run.Difficulty.expert)
                    }
                }
                
                Section("Preferences") {
                    Toggle("Avoid Crowded Runs", isOn: $viewModel.avoidCrowds)
                    Toggle("Prefer Less Strenuous Routes", isOn: $viewModel.preferLessStrenuous)
                }
                
                if appState.selectedResort != nil {
                    Section("Start Navigation") {
                        Button("Choose Start & End Points") {
                            viewModel.showRouteSelection = true
                        }
                    }
                } else {
                    Section {
                        Text("Select a resort to start navigation")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Navigation Setup")
            .sheet(isPresented: $viewModel.showRouteSelection) {
                if let resort = appState.selectedResort {
                    RouteSelectionView(resort: resort, viewModel: viewModel)
                }
            }
        }
    }
}

// MARK: - AR Resort View
struct ARResortView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationView {
            Group {
                if let resort = appState.selectedResort {
                    ContentUnavailableView(
                        "AR View Coming Soon",
                        systemImage: "camera.fill",
                        description: Text("AR features for \(resort.name) will be available in a future update.")
                    )
                } else {
                    ContentUnavailableView(
                        "No Resort Selected",
                        systemImage: "mountain.2",
                        description: Text("Select a resort to view AR features")
                    )
                }
            }
            .navigationTitle("AR View")
        }
    }
}

// MARK: - Supporting Views
struct ResortRowView: View {
    let resort: Resort
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(resort.name)
                .font(.headline)
            
            if let weather = resort.weather {
                HStack {
                    Image(systemName: "thermometer")
                    Text("\(Int(weather.temperature))°F")
                    Text("•")
                    Text(weather.conditions)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            HStack {
                StatusIndicator(
                    count: resort.lifts.filter { $0.status == .open }.count,
                    total: resort.lifts.count,
                    type: "Lifts"
                )
                
                Spacer()
                
                StatusIndicator(
                    count: resort.runs.filter { $0.status == .open }.count,
                    total: resort.runs.count,
                    type: "Runs"
                )
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}

struct StatusIndicator: View {
    let count: Int
    let total: Int
    let type: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(count > 0 ? .green : .red)
                .frame(width: 8, height: 8)
            
            Text("\(count)/\(total) \(type)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
} 