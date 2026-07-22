import Foundation

protocol ContentCatalogSource {
    var identifier: String { get }

    func loadData() throws -> Data
}

enum ContentCatalogSourceError: Error, Equatable, LocalizedError {
    case resourceNotFound(name: String, extension: String)
    case unreadableResource(path: String, reason: String)

    var errorDescription: String? {
        switch self {
        case let .resourceNotFound(name, fileExtension):
            "Catalog resource \(name).\(fileExtension) was not found."
        case let .unreadableResource(path, reason):
            "Catalog resource at \(path) could not be read: \(reason)"
        }
    }
}

struct BundleContentCatalogSource: ContentCatalogSource {
    let identifier: String
    let bundle: Bundle
    let resourceName: String
    let resourceExtension: String

    init(
        identifier: String = "bundled",
        bundle: Bundle = .main,
        resourceName: String = "ContentCatalog.v1",
        resourceExtension: String = "json"
    ) {
        self.identifier = identifier
        self.bundle = bundle
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
    }

    func loadData() throws -> Data {
        guard let url = bundle.url(
            forResource: resourceName,
            withExtension: resourceExtension
        ) else {
            throw ContentCatalogSourceError.resourceNotFound(
                name: resourceName,
                extension: resourceExtension
            )
        }

        do {
            return try Data(contentsOf: url, options: .mappedIfSafe)
        } catch {
            throw ContentCatalogSourceError.unreadableResource(
                path: url.path,
                reason: error.localizedDescription
            )
        }
    }
}

struct DataContentCatalogSource: ContentCatalogSource {
    let identifier: String
    let data: Data

    func loadData() throws -> Data {
        data
    }
}
