import Foundation
import Observation

@MainActor
@Observable
final class AppEnvironment {
    var selectedTab: AppTab
    let buildConfiguration: BuildConfiguration

    init(
        selectedTab: AppTab = .today,
        buildConfiguration: BuildConfiguration = .current
    ) {
        self.selectedTab = selectedTab
        self.buildConfiguration = buildConfiguration
    }

    func resetNavigation() {
        selectedTab = .today
    }
}

struct BuildConfiguration: Equatable, Sendable {
    enum Mode: String, Sendable {
        case debug
        case release
    }

    let appName: String
    let bundleIdentifier: String
    let mode: Mode

    static let current = BuildConfiguration(
        appName: "Evolve",
        bundleIdentifier: Bundle.main.bundleIdentifier ?? "com.evolve.app",
        mode: currentMode
    )

    private static var currentMode: Mode {
        #if DEBUG
        .debug
        #else
        .release
        #endif
    }
}
