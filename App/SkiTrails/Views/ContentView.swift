import SwiftUI
import MapKit
import SkiTrailsCore
import CoreLocation

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                mainContent
            }
        } else {
            NavigationView {
                mainContent
            }
            .navigationViewStyle(.stack)
        }
    }
    
    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            ResortListView()
                .tabItem {
                    Label("Resorts", systemImage: "mountain.2")
                }
                .tag(0)
            
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
                .tag(1)
            
            TrailStatusView()
                .tabItem {
                    Label("Trails", systemImage: "figure.skiing.downhill")
                }
                .tag(2)
            
            NavigationView {
                NavigationSetupView(viewModel: NavigationViewModel())
            }
            .tabItem {
                Label("Navigation", systemImage: "location.north.circle")
            }
            .tag(3)
            
            ARResortView()
                .tabItem {
                    Label("AR View", systemImage: "camera.viewfinder")
                }
                .tag(4)
        }
    }
}

struct ResortListView: View {
    @StateObject private var viewModel = ResortViewModel()
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(appState.resorts) { resort in
                        ResortRowView(resort: resort)
                            .onTapGesture {
                                viewModel.selectResort(resort)
                            }
                    }
                }
            }
        }
        .navigationTitle("Ski Resorts")
        .task {
            await appState.loadResorts()
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

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

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $viewModel.region) {
                if let resort = viewModel.selectedResort {
                    Marker(resort.name, coordinate: CLLocationCoordinate2D(
                        latitude: resort.location.latitude,
                        longitude: resort.location.longitude
                    ))
                }
            }
            
            if let resort = viewModel.selectedResort {
                ResortDetailCard(resort: resort)
                    .padding()
                    .transition(.move(edge: .bottom))
            }
        }
        .navigationTitle("Resort Map")
        .animation(.spring(), value: viewModel.selectedResort)
    }
}

struct ResortDetailCard: View {
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
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
}

struct TrailStatusView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ResortViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let resort = viewModel.selectedResort {
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
            if let resort = viewModel.selectedResort {
                await viewModel.selectResort(resort)
            }
        }
    }
}

struct LiftStatusRow: View {
    let lift: Lift
    
    var body: some View {
        HStack {
            Text(lift.name)
            
            Spacer()
            
            StatusBadge(status: lift.status)
        }
    }
}

struct RunStatusRow: View {
    let run: Run
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(run.name)
                
                HStack {
                    DifficultyIndicator(difficulty: run.difficulty)
                    Text("\(Int(run.length))m • \(Int(run.verticalDrop))m vert")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            StatusBadge(status: run.status)
        }
    }
}

struct StatusBadge: View {
    let status: Status
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .clipShape(Capsule())
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
} 