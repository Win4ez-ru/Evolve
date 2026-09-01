import SwiftUI

struct ConceptContentRenderer: View {
    let blocks: [ContentBlockSpec]

    var body: some View {
        ContentRendererFrame(
            eyebrow: "Core concept",
            symbol: "lightbulb.max.fill"
        ) {
            ContentBlockList(blocks: blocks)
        }
    }
}

struct PrincipleContentRenderer: View {
    let blocks: [ContentBlockSpec]

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.large) {
            RoundedRectangle(cornerRadius: AppRadius.full, style: .continuous)
                .fill(AppColor.accent)
                .frame(width: 4)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.large) {
                RendererEyebrow(
                    title: "Guiding principle",
                    symbol: "compass.drawing"
                )
                ContentBlockList(blocks: blocks)
            }
        }
        .padding(.vertical, AppSpacing.small)
    }
}

struct DilemmaContentRenderer: View {
    let blocks: [ContentBlockSpec]

    var body: some View {
        ContentRendererFrame(
            eyebrow: "Tension to hold",
            symbol: "arrow.trianglehead.2.clockwise.rotate.90"
        ) {
            ContentBlockList(blocks: blocks)
        }
    }
}

struct ProblemContentRenderer: View {
    let blocks: [ContentBlockSpec]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            RendererEyebrow(
                title: "Trace before checking",
                symbol: "terminal.fill"
            )

            ContentBlockList(blocks: blocks)
        }
    }
}

struct WorkedExampleContentRenderer: View {
    let blocks: [ContentBlockSpec]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            RendererEyebrow(
                title: "Worked example",
                symbol: "list.number"
            )

            ForEach(Array(blocks.sorted(by: { $0.order < $1.order }).enumerated()), id: \.element.id) { index, block in
                HStack(alignment: .top, spacing: AppSpacing.medium) {
                    Text("\(index + 1)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.accent)
                        .frame(width: 28, height: 28)
                        .background(AppColor.accent.opacity(0.10))
                        .clipShape(Circle())
                        .accessibilityHidden(true)

                    ContentBlockRenderer(block: block)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Step \(index + 1). \(block.accessibilityLabel ?? block.content)")
            }
        }
    }
}

struct StandardContentRenderer: View {
    let kindName: String
    let blocks: [ContentBlockSpec]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            RendererEyebrow(
                title: kindName,
                symbol: "rectangle.and.text.magnifyingglass"
            )
            ContentBlockList(blocks: blocks)
        }
    }
}

struct ContentBlockList: View {
    let blocks: [ContentBlockSpec]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            ForEach(blocks.sorted(by: { $0.order < $1.order })) { block in
                ContentBlockRenderer(block: block)
            }
        }
    }
}

private struct ContentRendererFrame<Content: View>: View {
    let eyebrow: String
    let symbol: String
    private let content: Content

    init(
        eyebrow: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) {
        self.eyebrow = eyebrow
        self.symbol = symbol
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            RendererEyebrow(title: eyebrow, symbol: symbol)
            content
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }
}

private struct RendererEyebrow: View {
    let title: String
    let symbol: String

    var body: some View {
        Label(title, systemImage: symbol)
            .font(AppTypography.caption)
            .foregroundStyle(AppColor.accent)
            .textCase(.uppercase)
            .fixedSize(horizontal: false, vertical: true)
    }
}
