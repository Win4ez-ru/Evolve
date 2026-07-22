import Testing
@testable import Evolve

@Suite("Application shell")
@MainActor
struct AppSmokeTests {
    @Test("Every root tab has user-facing metadata")
    func tabMetadataIsComplete() {
        #expect(AppTab.allCases.count == 4)

        for tab in AppTab.allCases {
            #expect(!tab.title.isEmpty)
            #expect(!tab.systemImage.isEmpty)
        }
    }

    @Test("The root view can be constructed")
    func constructsRootView() {
        _ = AppRootView()
    }
}
