import Foundation

struct LoadedContentCatalog: Equatable, Sendable {
    let definition: ContentCatalogDefinition
    let sourceSchemaVersion: Int
    let didMigrate: Bool
}

enum ContentCatalogDecodingError: Error, Equatable, LocalizedError, Sendable {
    case emptyData
    case malformedJSON(String)
    case invalidRoot
    case missingSchemaVersion
    case unsupportedSchemaVersion(found: Int, supported: Int)
    case migrationFailed(from: Int, reason: String)
    case decodingFailed(String)
    case validationFailed([ContentValidationIssue])

    var errorDescription: String? {
        switch self {
        case .emptyData:
            "Catalog data is empty."
        case let .malformedJSON(reason):
            "Catalog is not valid JSON: \(reason)"
        case .invalidRoot:
            "Catalog JSON root must be an object."
        case .missingSchemaVersion:
            "Catalog does not declare schemaVersion."
        case let .unsupportedSchemaVersion(found, supported):
            "Catalog schema \(found) is unsupported; this app supports schema \(supported)."
        case let .migrationFailed(version, reason):
            "Catalog migration from schema \(version) failed: \(reason)"
        case let .decodingFailed(reason):
            "Catalog does not match the content schema: \(reason)"
        case let .validationFailed(issues):
            "Catalog validation failed with \(issues.count) issue(s)."
        }
    }
}

struct ContentCatalogMigrationResult: Sendable {
    let data: Data
    let sourceVersion: Int
    let finalVersion: Int

    var didMigrate: Bool {
        sourceVersion != finalVersion
    }
}

struct ContentCatalogMigrator {
    static let currentSchemaVersion = 1

    func migrateToCurrentSchema(_ data: Data) throws -> ContentCatalogMigrationResult {
        guard !data.isEmpty else {
            throw ContentCatalogDecodingError.emptyData
        }

        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw ContentCatalogDecodingError.malformedJSON(error.localizedDescription)
        }

        guard var root = object as? [String: Any] else {
            throw ContentCatalogDecodingError.invalidRoot
        }
        guard let sourceVersion = root["schemaVersion"] as? Int else {
            throw ContentCatalogDecodingError.missingSchemaVersion
        }
        guard sourceVersion <= Self.currentSchemaVersion else {
            throw ContentCatalogDecodingError.unsupportedSchemaVersion(
                found: sourceVersion,
                supported: Self.currentSchemaVersion
            )
        }

        var version = sourceVersion
        while version < Self.currentSchemaVersion {
            switch version {
            case 0:
                root = try migrateV0ToV1(root)
                version = 1
            default:
                throw ContentCatalogDecodingError.unsupportedSchemaVersion(
                    found: version,
                    supported: Self.currentSchemaVersion
                )
            }
        }

        do {
            let migratedData = try JSONSerialization.data(
                withJSONObject: root,
                options: [.sortedKeys]
            )
            return ContentCatalogMigrationResult(
                data: migratedData,
                sourceVersion: sourceVersion,
                finalVersion: version
            )
        } catch {
            throw ContentCatalogDecodingError.migrationFailed(
                from: sourceVersion,
                reason: error.localizedDescription
            )
        }
    }

    private func migrateV0ToV1(_ source: [String: Any]) throws -> [String: Any] {
        var root = source
        guard var units = root["contentUnits"] as? [[String: Any]] else {
            throw ContentCatalogDecodingError.migrationFailed(
                from: 0,
                reason: "contentUnits is missing or has an invalid shape."
            )
        }

        for index in units.indices where units[index]["safety"] == nil {
            units[index]["safety"] = [
                "level": SafetyLevel.standard.rawValue,
                "requiresExpertReview": false
            ]
        }

        root["contentUnits"] = units
        root["catalogVersion"] = root["catalogVersion"] ?? 1
        root["schemaVersion"] = 1
        return root
    }
}

struct ContentCatalogDecoder {
    private let migrator: ContentCatalogMigrator
    private let decoder: JSONDecoder

    init(
        migrator: ContentCatalogMigrator = ContentCatalogMigrator(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.migrator = migrator
        self.decoder = decoder
    }

    func decode(_ data: Data) throws -> LoadedContentCatalog {
        let migration = try migrator.migrateToCurrentSchema(data)
        let definition: ContentCatalogDefinition

        do {
            definition = try decoder.decode(
                ContentCatalogDefinition.self,
                from: migration.data
            )
        } catch let error as DecodingError {
            throw ContentCatalogDecodingError.decodingFailed(Self.describe(error))
        } catch {
            throw ContentCatalogDecodingError.decodingFailed(error.localizedDescription)
        }

        do {
            try definition.validated()
        } catch let error as ContentValidationError {
            throw ContentCatalogDecodingError.validationFailed(error.issues)
        }

        return LoadedContentCatalog(
            definition: definition,
            sourceSchemaVersion: migration.sourceVersion,
            didMigrate: migration.didMigrate
        )
    }

    private static func describe(_ error: DecodingError) -> String {
        switch error {
        case let .typeMismatch(_, context),
             let .valueNotFound(_, context),
             let .keyNotFound(_, context),
             let .dataCorrupted(context):
            let path = context.codingPath
                .map(\.stringValue)
                .joined(separator: ".")
            return path.isEmpty
                ? context.debugDescription
                : "\(path): \(context.debugDescription)"
        @unknown default:
            return String(describing: error)
        }
    }
}
