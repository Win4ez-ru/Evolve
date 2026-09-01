import Foundation
import SwiftData
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

    @Test("A catalog failure on a fresh store enters recovery")
    func emptyCatalogFailureBlocksLaunch() throws {
        struct ExpectedFailure: Error {}

        let container = try PersistenceController.makeContainer(inMemory: true)
        let launch = AppLaunchResolver.resolve(
            persistence: PersistenceController.Resolution(
                container: container,
                availability: .persistent
            )
        ) { _ in
            throw ExpectedFailure()
        }

        switch launch.availability {
        case .catalogUnavailable:
            #expect(launch.catalogFailureReason != nil)
        case .ready, .persistenceUnavailable:
            Issue.record("A fresh store must not launch without learning content.")
        }
    }

    @Test("A catalog failure keeps an existing valid catalog available")
    func existingCatalogSurvivesBundledFailure() throws {
        struct ExpectedFailure: Error {}

        let container = try PersistenceController.makeContainer(inMemory: true)
        let source = DataContentCatalogSource(
            identifier: "existing-catalog",
            data: try JSONEncoder().encode(MVPContentFixtures.catalog)
        )
        _ = try ContentCatalogBootstrapper().install(
            from: source,
            in: container.mainContext
        )

        let launch = AppLaunchResolver.resolve(
            persistence: PersistenceController.Resolution(
                container: container,
                availability: .persistent
            )
        ) { _ in
            throw ExpectedFailure()
        }

        #expect(launch.availability == .ready)
        #expect(launch.catalogFailureReason != nil)
    }
}
