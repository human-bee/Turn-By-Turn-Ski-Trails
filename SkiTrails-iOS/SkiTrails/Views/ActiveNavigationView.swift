import SwiftUI
import SkiTrailsCore

typealias NavigationInstruction = NavigationViewModel.NavigationInstruction

struct ActiveNavigationView: View {
    @ObservedObject var viewModel: NavigationViewModel
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationView {
            Group {
                if let route = viewModel.currentRoute {
                    RouteContentView(route: route, viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Navigation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Stop") {
                        viewModel.stopNavigation()
                    }
                }
            }
        }
    }
}

private struct RouteContentView: View {
    let route: Route
    let viewModel: NavigationViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            RouteOverlayView(route: route)
                .frame(maxHeight: .infinity)
            
            RouteInfoView(route: route, viewModel: viewModel)
        }
    }
}

private struct RouteInfoView: View {
    let route: Route
    let viewModel: NavigationViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            if let nextInstruction = viewModel.nextInstruction {
                NextInstructionView(instruction: nextInstruction)
            }
            
            RouteStatsView(route: route)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(route.segments.indices, id: \.self) { index in
                        SegmentCard(segment: route.segments[index])
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(.ultraThinMaterial)
    }
}

private struct NextInstructionView: View {
    let instruction: NavigationInstruction
    
    var body: some View {
        HStack {
            Image(systemName: instruction.icon)
                .font(.title2)
            Text(instruction.text)
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}

private struct RouteStatsView: View {
    let route: Route
    
    var body: some View {
        HStack {
            Label(
                "\(Int(route.totalDistance)) meters",
                systemImage: "ruler"
            )
            
            Spacer()
            
            Label(
                formatDuration(route.estimatedTime),
                systemImage: "clock"
            )
        }
        .font(.headline)
        .padding(.horizontal)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        return "\(minutes) min"
    }
}

struct SegmentCard: View {
    let segment: Route.Segment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                
                Text(segmentName)
                    .font(.headline)
            }
            
            if case .run(let run) = segment.type {
                DifficultyIndicator(difficulty: run.difficulty)
            }
            
            Text("\(Int(segment.distance)) meters")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var iconName: String {
        switch segment.type {
        case .run:
            return "arrow.down.forward.circle.fill"
        case .lift:
            return "arrow.up.forward.circle.fill"
        case .connection:
            return "arrow.right.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch segment.type {
        case .run:
            return .blue
        case .lift:
            return .green
        case .connection:
            return .orange
        }
    }
    
    private var segmentName: String {
        switch segment.type {
        case .run(let run):
            return run.name
        case .lift(let lift):
            return lift.name
        case .connection:
            return "Connection"
        }
    }
}

#Preview {
    let appState = AppState()
    return ActiveNavigationView(viewModel: NavigationViewModel(appState: appState))
        .environmentObject(appState)
} 
