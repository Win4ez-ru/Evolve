import Foundation

enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case today
    case library
    case progress
    case profile

    var id: Self { self }

    var title: String {
        switch self {
        case .today:
            "Today"
        case .library:
            "Memory"
        case .progress:
            "Progress"
        case .profile:
            "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .today:
            "sparkles"
        case .library:
            "brain.head.profile"
        case .progress:
            "chart.line.uptrend.xyaxis"
        case .profile:
            "person.crop.circle"
        }
    }
}
