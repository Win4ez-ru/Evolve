import Foundation
import Testing
@testable import Evolve

@Suite("Content catalog decoding")
struct ContentCatalogDecodingTests {
    @Test("The bundled catalog decodes and validates")
    func decodesBundledCatalog() throws {
        let data = try BundleContentCatalogSource(bundle: .main).loadData()
        let loaded = try ContentCatalogDecoder().decode(data)

        #expect(loaded.definition.schemaVersion == 1)
        #expect(loaded.definition.catalogVersion == 1)
        #expect(loaded.definition.categories.count == 3)
        #expect(loaded.definition.contentUnits.count == 3)
        #expect(!loaded.didMigrate)
    }

    @Test("Schema zero migrates by adding safety metadata")
    func migratesSchemaZero() throws {
        let data = try makeFixtureData { root in
            root["schemaVersion"] = 0
            root.removeValue(forKey: "catalogVersion")

            var units = try #require(root["contentUnits"] as? [[String: Any]])
            for index in units.indices {
                units[index].removeValue(forKey: "safety")
            }
            root["contentUnits"] = units
        }

        let loaded = try ContentCatalogDecoder().decode(data)

        #expect(loaded.sourceSchemaVersion == 0)
        #expect(loaded.didMigrate)
        #expect(loaded.definition.schemaVersion == 1)
        #expect(loaded.definition.catalogVersion == 1)
        #expect(loaded.definition.contentUnits.allSatisfy { $0.safety.level == .standard })
    }

    @Test("A future schema is rejected explicitly")
    func rejectsFutureSchema() throws {
        let data = try makeFixtureData { root in
            root["schemaVersion"] = 99
        }

        do {
            _ = try ContentCatalogDecoder().decode(data)
            Issue.record("A future schema unexpectedly decoded.")
        } catch let error as ContentCatalogDecodingError {
            #expect(error == .unsupportedSchemaVersion(found: 99, supported: 1))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Malformed JSON and invalid content have different errors")
    func distinguishesSyntaxFromValidation() throws {
        do {
            _ = try ContentCatalogDecoder().decode(Data("{".utf8))
            Issue.record("Malformed JSON unexpectedly decoded.")
        } catch let error as ContentCatalogDecodingError {
            guard case .malformedJSON = error else {
                Issue.record("Expected malformedJSON, received \(error).")
                return
            }
        }

        let invalidData = try makeFixtureData { root in
            var units = try #require(root["contentUnits"] as? [[String: Any]])
            units[0]["blocks"] = []
            root["contentUnits"] = units
        }

        do {
            _ = try ContentCatalogDecoder().decode(invalidData)
            Issue.record("Invalid catalog unexpectedly decoded.")
        } catch let error as ContentCatalogDecodingError {
            guard case let .validationFailed(issues) = error else {
                Issue.record("Expected validationFailed, received \(error).")
                return
            }
            #expect(issues.contains { $0.path.contains("blocks") })
        }
    }

    private func makeFixtureData(
        mutate: (inout [String: Any]) throws -> Void
    ) throws -> Data {
        let encoded = try JSONEncoder().encode(MVPContentFixtures.catalog)
        let object = try JSONSerialization.jsonObject(with: encoded)
        var root = try #require(object as? [String: Any])
        try mutate(&root)
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }
}
