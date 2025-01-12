import SwiftUI
import SkiTrailsCore

struct ActiveNavigationView: View {
    @ObservedObject var viewModel: NavigationViewModel
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationView {
            Group {
                if let route = viewModel.currentRoute {
                    VStack(spacing: 0) {
                        RouteOverlayView(route: route)
                            .frame(maxHeight: .infinity)
                        
                        VStack(spacing: 16) {
                            // Next instruction display
                            if let nextInstruction = viewModel.nextInstruction {
                                HStack {
                                    Image(systemName: nextInstruction.icon)
                                        .font(.title2)
                                    Text(nextInstruction.text)
                                        .font(.headline)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.ultraThinMaterial)
                            }
                            
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
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(route.segments) { segment in
                                        SegmentCard(segment: segment)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        .background(.ultraThinMaterial)
                    }
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
                
                Text(segment.name)
                    .font(.headline)
            }
            
            if case .run(let difficulty) = segment.type {
                DifficultyIndicator(difficulty: difficulty)
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
}

#Preview {
    let appState = AppState()
    return ActiveNavigationView(viewModel: NavigationViewModel(appState: appState))
        .environmentObject(appState)
} 