struct RouteOverlayView: View {
    let route: Route
    @EnvironmentObject private var appState: AppState
    @Environment(\.contentViewModel) private var viewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Route")
                .font(.headline)
            
            HStack {
                Label("\(Int(route.totalDistance))m", systemName: "ruler")
                Spacer()
                Label(formatDuration(route.estimatedTime), systemName: "clock")
            }
            .font(.subheadline)
            
            // Check for closed segments
            if let closedSegments = findClosedSegments() {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Warning")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    Text("Some parts of your route are now closed:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(closedSegments, id: \.name) { segment in
                        Text("• \(segment.name) (\(segment.type))")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Button("Recalculate Route") {
                        recalculateRoute()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
                .padding(.vertical, 4)
            }
            
            Button("End Navigation") {
                withAnimation {
                    appState.endNavigation()
                    viewModel.routeCoordinates = []
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
    
    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: timeInterval) ?? ""
    }
    
    private struct ClosedSegment {
        let name: String
        let type: String
    }
    
    private func findClosedSegments() -> [ClosedSegment]? {
        var closedSegments: [ClosedSegment] = []
        
        for segment in route.segments {
            switch segment.type {
            case .lift(let lift):
                if lift.status == .closed || lift.status == .hold {
                    closedSegments.append(ClosedSegment(
                        name: lift.name,
                        type: "Lift"
                    ))
                }
            case .run(let run):
                if run.status != .open {
                    closedSegments.append(ClosedSegment(
                        name: run.name,
                        type: "Run"
                    ))
                }
            case .connection:
                break
            }
        }
        
        return closedSegments.isEmpty ? nil : closedSegments
    }
    
    private func recalculateRoute() {
        guard let currentLocation = appState.locationManager.currentLocation else {
            print("[Route] Cannot recalculate - no current location")
            return
        }
        
        // Get the last point of the current route
        guard let lastSegment = route.segments.last,
              let lastPoint = lastSegment.path.last else {
            print("[Route] Cannot recalculate - invalid route")
            return
        }
        
        // Start a new route from current location to the original destination
        Task {
            await appState.startNavigation(
                from: currentLocation.coordinate,
                to: CLLocationCoordinate2D(
                    latitude: lastPoint.latitude,
                    longitude: lastPoint.longitude
                ),
                viewModel: viewModel
            )
        }
    }
} 