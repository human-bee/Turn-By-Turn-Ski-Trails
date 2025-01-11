import SwiftUI

struct RouteDetailView: View {
    let route: Route
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        List {
            // Route Summary
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("\(Int(route.totalDistance))m", systemName: "ruler")
                        Spacer()
                        Label(formatDuration(route.estimatedTime), systemName: "clock")
                    }
                    
                    HStack {
                        Label("Difficulty", systemName: "figure.skiing.downhill")
                        Spacer()
                        DifficultyIndicator(difficulty: route.difficulty)
                    }
                }
            }
            
            // Route Segments
            Section("Route Details") {
                ForEach(route.segments.indices, id: \.self) { index in
                    let segment = route.segments[index]
                    RouteSegmentRow(segment: segment, index: index)
                }
            }
            
            // Actions
            Section {
                Button(action: {
                    startNavigation()
                }) {
                    Label("Start Navigation", systemName: "location.fill")
                }
                .foregroundColor(.blue)
                
                Button(action: {
                    shareRoute()
                }) {
                    Label("Share Route", systemName: "square.and.arrow.up")
                }
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

struct DifficultyIndicator: View {
    let difficulty: SkiDifficulty
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(difficulty.color)
                .frame(width: 12, height: 12)
            Text(difficulty.rawValue)
                .font(.subheadline)
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
        Route(
            segments: [
                Segment(
                    type: .lift(Lift(id: "1", name: "Express Lift", status: .open, capacity: 4, waitTime: 5)),
                    path: [
                        Segment.Location(latitude: 0, longitude: 0, altitude: 0),
                        Segment.Location(latitude: 1, longitude: 1, altitude: 100)
                    ],
                    distance: 1200
                ),
                Segment(
                    type: .run(Run(id: "2", name: "Blue Run", difficulty: .intermediate, status: .open, length: 800, verticalDrop: 200)),
                    path: [
                        Segment.Location(latitude: 1, longitude: 1, altitude: 100),
                        Segment.Location(latitude: 2, longitude: 2, altitude: 0)
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