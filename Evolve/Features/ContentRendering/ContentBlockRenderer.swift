import SwiftUI

struct ContentBlockRenderer: View {
    let block: ContentBlockSpec

    var body: some View {
        Group {
            switch ContentRendererResolver.blockRenderer(for: block.kind) {
            case .heading:
                Text(block.content)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

            case .paragraph:
                Text(block.content)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

            case .quote:
                quote

            case .code:
                CodeContentBlockRenderer(block: block)

            case .formula:
                formula

            case .media:
                mediaPlaceholder

            case .callout:
                callout
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(block.accessibilityLabel ?? block.content)
    }

    private var quote: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Image(systemName: "quote.opening")
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColor.accent)
                .accessibilityHidden(true)

            Text(block.content)
                .font(AppTypography.body)
                .italic()
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, AppSpacing.small)
    }

    private var formula: some View {
        ScrollView(.horizontal) {
            Text(block.content)
                .font(.system(.body, design: .monospaced, weight: .medium))
                .foregroundStyle(AppColor.textPrimary)
                .padding(AppSpacing.large)
        }
        .scrollIndicators(.hidden)
        .background(AppColor.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
    }

    private var callout: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Image(systemName: "sparkles")
                .foregroundStyle(AppColor.accent)
                .accessibilityHidden(true)

            Text(block.content)
                .font(AppTypography.supporting)
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.accent.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }

    private var mediaPlaceholder: some View {
        HStack(alignment: .center, spacing: AppSpacing.medium) {
            Image(systemName: block.kind.mediaSymbolName)
                .font(.title3)
                .foregroundStyle(AppColor.accent)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(block.kind.mediaDisplayName)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.accent)

                Text(block.content)
                    .font(AppTypography.supporting)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }
}

struct CodeContentBlockRenderer: View {
    let block: ContentBlockSpec

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .accessibilityHidden(true)

                Text(block.language?.uppercased() ?? "CODE")
                    .font(AppTypography.caption)
            }
            .foregroundStyle(AppColor.textSecondary)
            .padding(.horizontal, AppSpacing.large)
            .padding(.vertical, AppSpacing.medium)

            Divider()

            ScrollView(.horizontal) {
                Text(block.content)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(AppColor.textPrimary)
                    .textSelection(.enabled)
                    .padding(AppSpacing.large)
            }
            .scrollIndicators(.hidden)
        }
        .background(AppColor.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .stroke(AppColor.separator.opacity(0.45), lineWidth: 0.5)
        }
    }
}

private extension ContentBlockKind {
    var mediaSymbolName: String {
        switch self {
        case .image:
            "photo"
        case .audio:
            "waveform"
        case .video:
            "play.rectangle"
        case .heading,
             .paragraph,
             .quote,
             .code,
             .formula,
             .callout:
            "doc.richtext"
        }
    }

    var mediaDisplayName: String {
        switch self {
        case .image:
            "Image"
        case .audio:
            "Audio"
        case .video:
            "Video"
        case .heading,
             .paragraph,
             .quote,
             .code,
             .formula,
             .callout:
            "Media"
        }
    }
}
