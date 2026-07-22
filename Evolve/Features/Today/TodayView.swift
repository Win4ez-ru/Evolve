import SwiftData
import SwiftUI

struct TodayView: View {
    @Query(sort: \ContentCategory.sortOrder) private var categories: [ContentCategory]
    @Query(sort: \ContentUnit.title) private var contentUnits: [ContentUnit]

    @State private var presentsSession = false

    private let now: Date

    init(now: Date = .now) {
        self.now = now
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Today")
                        .font(AppTypography.screenTitle)

                    Text(now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(AppTypography.supporting)
                        .foregroundStyle(AppColor.textSecondary)
                }

                FoundationCard {
                    VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                        VStack(alignment: .leading, spacing: AppSpacing.medium) {
                            Label("Today’s focus", systemImage: "sparkles")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.accent)

                            Text("Three ideas. One clear ending.")
                                .font(AppTypography.sectionTitle)

                            Text(
                                "A calm, finite session selected from your local catalog—no infinite feed and no surprise additions."
                            )
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(spacing: AppSpacing.large) {
                            metric(
                                value: "\(sessionPlan.items.count)",
                                label: "cards"
                            )
                            metric(
                                value: "\(sessionPlan.totalMinutes)",
                                label: "minutes"
                            )
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: AppSpacing.medium) {
                            ForEach(Array(sessionPlan.items.enumerated()), id: \.element.id) { index, item in
                                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.medium) {
                                    Text("\(index + 1)")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColor.accent)
                                        .frame(width: 22, height: 22)
                                        .background(AppColor.accent.opacity(0.10))
                                        .clipShape(Circle())

                                    Text(item.title)
                                        .font(AppTypography.supporting)
                                        .foregroundStyle(AppColor.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }

                        Button("Start learning session") {
                            presentsSession = true
                        }
                        .buttonStyle(.primaryAction)
                        .disabled(sessionPlan.isEmpty)
                        .accessibilityHint(
                            "Opens a finite vertical session with \(sessionPlan.items.count) cards"
                        )
                    }
                }

                Text("You can stop at any point. Evolve always shows where the session ends.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.xLarge)
        }
        .background(AppColor.groupedBackground)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $presentsSession) {
            LearningSessionView(plan: sessionPlan) {
                presentsSession = false
            }
        }
    }

    private var sessionPlan: LearningSessionPlan {
        LearningSessionPlan(
            contentUnits: contentUnits,
            categories: categories
        )
    }

    private func metric(value: String, label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xSmall) {
            Text(value)
                .font(AppTypography.sectionTitle)
                .monospacedDigit()

            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        TodayView(now: Date(timeIntervalSince1970: 1_750_000_000))
    }
}
