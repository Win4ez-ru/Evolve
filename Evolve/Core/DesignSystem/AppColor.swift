import SwiftUI

enum AppColor {
    static let background = Color(uiColor: .systemBackground)
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let elevatedSurface = Color(uiColor: .tertiarySystemBackground)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let separator = Color(uiColor: .separator)
    static let accent = Color.accentColor
    static let onAccent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? .black : .white
    })
    static let heroActionBackground = Primitive.white
    static let heroActionForeground = Primitive.indigoLight
    static let success = Color(uiColor: .systemGreen)
    static let danger = Color(uiColor: .systemRed)

    enum Primitive {
        static let white = Color.white
        static let black = Color.black
        static let groupedLight = Color(red: 0.949, green: 0.949, blue: 0.969)
        static let surfaceLight = Color(red: 0.949, green: 0.949, blue: 0.969)
        static let surfaceDark = Color(red: 0.110, green: 0.110, blue: 0.118)
        static let elevatedDark = Color(red: 0.173, green: 0.173, blue: 0.180)
        static let secondaryLabelLight = Color(red: 0.235, green: 0.235, blue: 0.263).opacity(0.60)
        static let secondaryLabelDark = Color(red: 0.922, green: 0.922, blue: 0.961).opacity(0.60)
        static let separatorLight = Color(red: 0.235, green: 0.235, blue: 0.263).opacity(0.29)
        static let separatorDark = Color(red: 0.329, green: 0.329, blue: 0.345).opacity(0.60)
        static let indigoLight = Color(red: 0.345, green: 0.337, blue: 0.839)
        static let indigoDark = Color(red: 0.369, green: 0.361, blue: 0.902)
        static let greenLight = Color(red: 0.204, green: 0.780, blue: 0.349)
        static let greenDark = Color(red: 0.188, green: 0.820, blue: 0.345)
        static let redLight = Color(red: 1.000, green: 0.231, blue: 0.188)
        static let redDark = Color(red: 1.000, green: 0.271, blue: 0.227)
    }
}
