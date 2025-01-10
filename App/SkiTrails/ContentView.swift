import SwiftUI
import SkiTrailsCore

// MARK: - ViewModels
final class ResortViewModel: ObservableObject {
    @Published private(set) var selectedResort: Resort?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private var statusRefreshTask: Task<Void, Never>?
    private let refreshInterval: TimeInterval = 60 // Refresh every minute
    
    init() {
        startStatusRefreshTimer()
    }
    
    deinit {
        statusRefreshTask?.cancel()
    }
    
    func selectResort(_ resort: Resort) {
        selectedResort = resort
    }
    
    private func startStatusRefreshTimer() {
        statusRefreshTask = Task {
            while !Task.isCancelled {
                await refreshResortStatus()
                try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
            }
        }
    }
    
    private func refreshResortStatus() async {
        guard let resort = selectedResort else { return }
        
        do {
            isLoading = true
            // TODO: Implement API call to fetch updated status
            print("Refreshing status for resort: \(resort.name)")
            try await Task.sleep(nanoseconds: 1_000_000_000)
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
}

final class NavigationViewModel: ObservableObject {
    @Published private(set) var currentRoute: RoutingEngine.Route?
    @Published private(set) var isNavigating = false
    @Published private(set) var isCalculating = false
    @Published private(set) var error: Error?
    
    private let routingEngine: RoutingEngine
    
    init(routingEngine: RoutingEngine = RoutingEngine()) {
        self.routingEngine = routingEngine
    }
    
    func startNavigation(from start: Location, to end: Location, in resort: Resort) async {
        isCalculating = true
        error = nil
        
        do {
            if let route = await routingEngine.findRoute(from: start, to: end, in: resort) {
                currentRoute = route
                isNavigating = true
            } else {
                throw NavigationError.noRouteFound
            }
        } catch {
            self.error = error
        }
        
        isCalculating = false
    }
    
    func endNavigation() {
        isNavigating = false
        currentRoute = nil
        error = nil
    }
    
    enum NavigationError: LocalizedError {
        case noRouteFound
        
        var errorDescription: String? {
            switch self {
            case .noRouteFound:
                return "No valid route found between the selected points"
            }
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var resortViewModel = ResortViewModel()
    @StateObject private var navigationViewModel = NavigationViewModel()
    
    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            
            VStack {
                Text("SkiTrails")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                
                if resortViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if let error = resortViewModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .padding()
                } else if let resort = resortViewModel.selectedResort {
                    VStack(spacing: 16) {
                        Text(resort.name)
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        if let weather = resort.weather {
                            Text("\(Int(weather.temperature))°F - \(weather.conditions)")
                                .foregroundColor(.white)
                        }
                        
                        if navigationViewModel.isCalculating {
                            ProgressView("Calculating route...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .foregroundColor(.white)
                        } else if let route = navigationViewModel.currentRoute {
                            VStack(alignment: .leading) {
                                Text("Current Route:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                ForEach(route.segments, id: \.id) { segment in
                                    switch segment.type {
                                    case .lift(let lift):
                                        Text("Take \(lift.name) up")
                                    case .run(let run):
                                        Text("Ski down \(run.name)")
                                    }
                                }
                                .foregroundColor(.white)
                                
                                Button("End Navigation") {
                                    navigationViewModel.endNavigation()
                                }
                                .foregroundColor(.white)
                                .padding(.top)
                            }
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(10)
                        }
                        
                        if let error = navigationViewModel.error {
                            Text(error.localizedDescription)
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                } else {
                    Text("Select a resort")
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
} 