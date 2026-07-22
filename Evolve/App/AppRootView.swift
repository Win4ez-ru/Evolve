import SwiftUI

struct AppRootView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var environment = environment

        TabView(selection: $environment.selectedTab) {
            Tab(
                AppTab.today.title,
                systemImage: AppTab.today.systemImage,
                value: AppTab.today
            ) {
                NavigationStack {
                    TodayView()
                }
            }

            Tab(
                AppTab.library.title,
                systemImage: AppTab.library.systemImage,
                value: AppTab.library
            ) {
                NavigationStack {
                    LibraryView()
                }
            }

            Tab(
                AppTab.progress.title,
                systemImage: AppTab.progress.systemImage,
                value: AppTab.progress
            ) {
                NavigationStack {
                    ProgressView()
                }
            }

            Tab(
                AppTab.profile.title,
                systemImage: AppTab.profile.systemImage,
                value: AppTab.profile
            ) {
                NavigationStack {
                    ProfileView()
                }
            }
        }
        .tint(AppColor.accent)
    }
}

#Preview {
    AppRootView()
        .environment(PreviewSupport.environment())
        .modelContainer(PreviewSupport.modelContainer())
}
