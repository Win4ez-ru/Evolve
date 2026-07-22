import SwiftUI

struct LibraryView: View {
    var body: some View {
        FeaturePlaceholderView(
            title: "Library",
            subtitle: "A calm home for saved and practiced knowledge.",
            systemImage: "books.vertical.fill",
            nextStage: "Content states, filters, and collections will be added after the interaction system."
        )
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
}
