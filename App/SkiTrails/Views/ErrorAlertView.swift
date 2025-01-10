import SwiftUI

struct ErrorAlertView: View {
    let error: UserFacingError
    let dismissAction: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                // Error Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                
                // Error Title
                Text(error.title)
                    .font(.headline)
                
                // Error Message
                Text(error.message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                
                // Recovery Suggestion
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Dismiss Button
                Button("Dismiss") {
                    dismissAction()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .padding()
            
            Spacer()
        }
        .background(Color.black.opacity(0.4))
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview {
    ErrorAlertView(
        error: UserFacingError(
            title: "Network Error",
            message: "Failed to load resort data",
            recoverySuggestion: "Please check your internet connection and try again."
        )
    ) {
        // Dismiss action
    }
} 