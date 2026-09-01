import Foundation
import Observation
import SwiftUI

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

struct PersistenceFailure: Identifiable {
    let id = UUID()
    let operation: String
    let underlyingDescription: String

    init(operation: String, error: Error) {
        self.operation = operation
        underlyingDescription = error.localizedDescription
    }

    var title: String {
        "Couldn’t \(operation)"
    }

    var message: String {
        let guidance = "Your last change was not saved. Check available device storage and try again."

        #if DEBUG
        return "\(guidance)\n\n\(underlyingDescription)"
        #else
        return guidance
        #endif
    }
}

extension View {
    func persistenceFailureAlert(
        _ failure: Binding<PersistenceFailure?>
    ) -> some View {
        alert(item: failure) { failure in
            Alert(
                title: Text(failure.title),
                message: Text(failure.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
