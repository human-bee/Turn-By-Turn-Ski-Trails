import SwiftUI
import SkiTrailsCore

struct RouteDetailView: View {
    let route: Route
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        List {
            // Route Summary
            Section {
                Label("Route Details", systemImage: "map")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("\(Int(route.totalDistance))m", systemImage: "ruler")
                        Spacer()
                        Label(formatDuration(route.estimatedTime), systemImage: "clock")
                    }
                    
                    HStack {
                        Label("Difficulty", systemImage: "figure.skiing.downhill")
                        Spacer()
                        DifficultyIndicator(difficulty: route.difficulty)
                    }
                }
            } header: {
                Text("Summary")
            }
            
            // Route Segments
            Section {
                ForEach(route.segments.indices, id: \.self) { index in
                    let segment = route.segments[index]
                    RouteSegmentRow(segment: segment, index: index)
                }
            } header: {
                Text("Route Details")
            }
            
            // Actions
            Section {
                Button(action: {
                    startNavigation()
                }) {
                    Label("Start Navigation", systemImage: "location.fill")
                }
                .foregroundColor(.blue)
                
                Button(action: {
                    shareRoute()
                }) {
                    Label("Share Route", systemImage: "square.and.arrow.up")
                }
            } header: {
                Text("Actions")
            }
        }
        .navigationTitle("Route Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: timeInterval) ?? ""
    }
    
    private func startNavigation() {
        appState.activeRoute = route
        appState.navigationActive = true
        dismiss()
    }
    
    private func shareRoute() {
        // Implement route sharing functionality
    }
}

struct RouteSegmentRow: View {
    let segment: Route.Segment
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Segment number
            ZStack {
                Circle()
                    .fill(.blue)
                    .frame(width: 24, height: 24)
                Text("\(index + 1)")
                    .foregroundColor(.white)
                    .font(.caption.bold())
            }
            
            // Segment details
            VStack(alignment: .leading, spacing: 4) {
                Text(segmentTitle)
                    .font(.headline)
                Text("\(Int(segment.distance))m")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Segment icon
            Image(systemName: segmentIcon)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
    
    private var segmentTitle: String {
        switch segment.type {
        case .run(let run):
            return run.name
        case .lift(let lift):
            return lift.name
        case .connection:
            return "Connection"
        }
    }
    
    private var segmentIcon: String {
        switch segment.type {
        case .run:
            return "figure.skiing.downhill"
        case .lift:
            return "arrow.up"
        case .connection:
            return "arrow.right"
        }
    }
}

#if DEBUG
struct RouteDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RouteDetailView(route: .preview)
                .environmentObject(AppState())
        }
    }
}
#endif

// MARK: - Preview Helpers
extension Route {
    static var preview: Route {
        let location1 = Route.Segment.Location(latitude: 0, longitude: 0, altitude: 0)
        let location2 = Route.Segment.Location(latitude: 1, longitude: 1, altitude: 100)
        let location3 = Route.Segment.Location(latitude: 2, longitude: 2, altitude: 0)
        
        return Route(
            segments: [
                Segment(
                    type: .lift(Lift(
                        id: EntityID(UUID()),
                        name: "Express Lift",
                        status: .open,
                        startLocation: Location(latitude: location1.latitude, longitude: location1.longitude, altitude: location1.altitude),
                        endLocation: Location(latitude: location2.latitude, longitude: location2.longitude, altitude: location2.altitude),
                        capacity: 4,
                        waitTime: 5
                    )),
                    path: [
                        location1,
                        location2
                    ],
                    distance: 1200
                ),
                Segment(
                    type: .run(Run(
                        id: EntityID(UUID()),
                        name: "Blue Run",
                        difficulty: .intermediate,
                        status: .open,
                        startLocation: Location(latitude: location2.latitude, longitude: location2.longitude, altitude: location2.altitude),
                        endLocation: Location(latitude: location3.latitude, longitude: location3.longitude, altitude: location3.altitude),
                        length: 800,
                        verticalDrop: 200
                    )),
                    path: [
                        location2,
                        location3
                    ],
                    distance: 800
                )
            ],
            totalDistance: 2000,
            estimatedTime: 1800, // 30 minutes
            difficulty: .intermediate
        )
    }
} 
