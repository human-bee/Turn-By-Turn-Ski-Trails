import SwiftUI

struct ActiveNavigationView: View {
    @ObservedObject var viewModel: NavigationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            // Map with route overlay
            RouteOverlayView(route: viewModel.currentRoute)
                .overlay(alignment: .topTrailing) {
                    Button(action: viewModel.stopNavigation) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
            
            // Navigation instructions
            VStack(spacing: 16) {
                if let nextInstruction = viewModel.nextInstruction {
                    HStack {
                        Image(systemName: nextInstruction.icon)
                            .font(.title)
                        Text(nextInstruction.text)
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                }
                
                // Progress indicators
                HStack {
                    VStack(alignment: .leading) {
                        Text("Distance")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.remainingDistance)
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.estimatedTime)
                            .font(.headline)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
            }
            .padding()
        }
    }
}

#Preview {
    ActiveNavigationView(viewModel: NavigationViewModel())
} 