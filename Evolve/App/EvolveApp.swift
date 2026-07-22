import OSLog
import SwiftData
import SwiftUI

@main
@MainActor
struct EvolveApp: App {
    private static let logger = Logger(
        subsystem: "com.evolve.app",
        category: "ContentCatalog"
    )

    @State private var environment: AppEnvironment
    private let modelContainer: ModelContainer

    init() {
        _environment = State(initialValue: AppEnvironment())
        let container = PersistenceController.shared
        modelContainer = container

        do {
            let report = try ContentCatalogBootstrapper().install(
                from: BundleContentCatalogSource(),
                in: container.mainContext
            )
            Self.logger.info(
                "Bundled catalog \(report.outcome.rawValue, privacy: .public), revision \(report.catalogVersion)."
            )
        } catch {
            Self.logger.error(
                "Bundled catalog rejected; keeping the last valid local catalog: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(environment)
        }
        .modelContainer(modelContainer)
    }
}
