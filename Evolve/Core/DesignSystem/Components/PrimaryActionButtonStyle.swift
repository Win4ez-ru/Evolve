import SwiftUI

struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.action)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, AppSpacing.large)
            .background(background(configuration: configuration))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppRadius.medium,
                    style: .continuous
                )
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(
                AppMotion.session(reduceMotion: reduceMotion),
                value: configuration.isPressed
            )
    }

    private func background(configuration: Configuration) -> Color {
        configuration.isPressed ? AppColor.accent.opacity(0.82) : AppColor.accent
    }
}

extension ButtonStyle where Self == PrimaryActionButtonStyle {
    static var primaryAction: PrimaryActionButtonStyle {
        PrimaryActionButtonStyle()
    }
}

#Preview {
    Button("Start session") {}
        .buttonStyle(.primaryAction)
        .padding()
}
