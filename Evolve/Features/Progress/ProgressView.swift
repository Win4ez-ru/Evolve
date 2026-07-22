import SwiftUI

struct ProgressView: View {
    var body: some View {
        FeaturePlaceholderView(
            title: "Progress",
            subtitle: "Evidence of understanding, memory, and application.",
            systemImage: "chart.line.uptrend.xyaxis",
            nextStage: "Evidence-weighted progress will appear after attempts and review records exist."
        )
    }
}

#Preview {
    NavigationStack {
        ProgressView()
    }
}
