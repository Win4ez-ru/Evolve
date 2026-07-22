import SwiftUI

struct ProfileView: View {
    var body: some View {
        FeaturePlaceholderView(
            title: "Profile",
            subtitle: "Goals, interests, pace, and accessibility preferences.",
            systemImage: "person.crop.circle.fill",
            nextStage: "Onboarding and personalization settings will be introduced after the learning loop works locally."
        )
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
