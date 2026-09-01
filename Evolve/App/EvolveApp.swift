import OSLog
import SwiftData
import SwiftUI

enum AppLaunchAvailability: Equatable {
    case ready
    case persistenceUnavailable(reason: String)
    case catalogUnavailable(reason: String)
}

@MainActor
enum AppLaunchResolver {
    struct Resolution {
        let availability: AppLaunchAvailability
        let catalogReport: ContentCatalogInstallationReport?
        let catalogFailureReason: String?
    }

    static func resolve(
        persistence: PersistenceController.Resolution,
        installCatalog: (ModelContext) throws -> ContentCatalogInstallationReport
    ) -> Resolution {
        switch persistence.availability {
        case .ephemeralFallback(let reason):
            return Resolution(
                availability: .persistenceUnavailable(reason: reason),
                catalogReport: nil,
                catalogFailureReason: nil
            )
        case .persistent:
            break
        }

        do {
            return Resolution(
                availability: .ready,
                catalogReport: try installCatalog(persistence.container.mainContext),
                catalogFailureReason: nil
            )
        } catch {
            let reason = error.localizedDescription
            return Resolution(
                availability: hasUsableCatalog(in: persistence.container.mainContext)
                    ? .ready
                    : .catalogUnavailable(reason: reason),
                catalogReport: nil,
                catalogFailureReason: reason
            )
        }
    }

    private static func hasUsableCatalog(in context: ModelContext) -> Bool {
        do {
            let categoryCount = try context.fetchCount(FetchDescriptor<ContentCategory>())
            let unitCount = try context.fetchCount(FetchDescriptor<ContentUnit>())
            let receiptCount = try context.fetchCount(FetchDescriptor<ContentCatalogReceipt>())
            return categoryCount > 0 && unitCount > 0 && receiptCount > 0
        } catch {
            return false
        }
    }
}

@main
@MainActor
struct EvolveApp: App {
    private static let logger = Logger(
        subsystem: "com.evolve.app",
        category: "ContentCatalog"
    )

    @State private var environment: AppEnvironment
    private let modelContainer: ModelContainer
    private let launchAvailability: AppLaunchAvailability

    init() {
        _environment = State(initialValue: AppEnvironment())
        let persistence = PersistenceController.shared
        let container = persistence.container
        modelContainer = container
        let launch = AppLaunchResolver.resolve(
            persistence: persistence
        ) { context in
            try ContentCatalogBootstrapper().install(
                from: BundleContentCatalogSource(),
                in: context
            )
        }
        launchAvailability = launch.availability

        if let report = launch.catalogReport {
            Self.logger.info(
                "Bundled catalog \(report.outcome.rawValue, privacy: .public), revision \(report.catalogVersion)."
            )
        }
        if let failureReason = launch.catalogFailureReason {
            Self.logger.error(
                "Bundled catalog rejected: \(failureReason, privacy: .public)"
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            switch launchAvailability {
            case .ready:
                AppRootView()
                    .environment(environment)
            case .persistenceUnavailable(let reason):
                LaunchUnavailableView(
                    systemImage: "externaldrive.badge.exclamationmark",
                    title: "Local data unavailable",
                    explanation: "Evolve could not open its local learning store. The app is paused so new progress cannot appear saved and then disappear.",
                    guidance: "Quit and reopen Evolve. If the problem continues, restart the device before creating new learning progress.",
                    reason: reason
                )
            case .catalogUnavailable(let reason):
                LaunchUnavailableView(
                    systemImage: "books.vertical.fill",
                    title: "Learning content unavailable",
                    explanation: "Evolve could not prepare its local learning catalog. The app is paused instead of opening an empty learning path.",
                    guidance: "Quit and reopen Evolve. If the problem continues, install the next available app update.",
                    reason: reason
                )
            }
        }
        .modelContainer(modelContainer)
    }
}

private struct LaunchUnavailableView: View {
    let systemImage: String
    let title: String
    let explanation: String
    let guidance: String
    let reason: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.weight(.semibold))

                Text(explanation)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text(guidance)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            #if DEBUG
            Text(reason)
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            #endif
        }
        .padding(32)
        .frame(maxWidth: 520)
        .accessibilityElement(children: .contain)
    }
}
