import Foundation
import SwiftData

@Model
final class AppInstallation {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var schemaVersion: Int

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        schemaVersion: Int = 3
    ) {
        self.id = id
        self.createdAt = createdAt
        self.schemaVersion = schemaVersion
    }
}
