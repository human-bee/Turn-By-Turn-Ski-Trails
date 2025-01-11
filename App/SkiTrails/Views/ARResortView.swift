import SwiftUI

struct ARResortView: View {
    var body: some View {
        ContentUnavailableView(
            "AR View Coming Soon",
            systemImage: "camera.viewfinder",
            description: Text("This feature is under development")
        )
    }
}

#Preview {
    ARResortView()
} 