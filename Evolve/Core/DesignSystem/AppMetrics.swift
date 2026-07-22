import SwiftUI

enum AppSpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 24
    static let xxLarge: CGFloat = 32
    static let section: CGFloat = 40
}

enum AppRadius {
    static let small: CGFloat = 10
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let full: CGFloat = 999
}

enum AppElevation {
    static let cardColor = Color.black.opacity(0.08)
    static let cardRadius: CGFloat = 24
    static let cardY: CGFloat = 8
}

enum AppMotion {
    enum Duration {
        static let instant: TimeInterval = 0
        static let quick: TimeInterval = 0.20
        static let standard: TimeInterval = 0.35
        static let emphasized: TimeInterval = 0.55
    }

    static func session(reduceMotion: Bool) -> Animation? {
        guard !reduceMotion else {
            return nil
        }

        return .snappy(duration: Duration.standard, extraBounce: 0)
    }
}
