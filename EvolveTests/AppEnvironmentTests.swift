import Testing
@testable import Evolve

@Suite("App environment")
@MainActor
struct AppEnvironmentTests {
    @Test("Today is the initial destination")
    func startsOnToday() {
        let environment = AppEnvironment()

        #expect(environment.selectedTab == .today)
    }

    @Test("Navigation can return to the initial destination")
    func resetsNavigation() {
        let environment = AppEnvironment(selectedTab: .profile)

        environment.resetNavigation()

        #expect(environment.selectedTab == .today)
    }
}
