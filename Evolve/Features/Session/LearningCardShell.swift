import SwiftUI

struct LearningCardShell: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var responseText = ""
    @State private var selectedOptions: Set<String> = []
    @State private var evaluatedResult: LearningInteractionResult?
    @State private var selectedInteractionID: UUID?
    @State private var confidence: AttemptConfidence = .medium
    @State private var startedAt = Date.now
    @State private var revealsReviewMaterial = false

    let item: LearningSessionItem
    let position: Int
    let total: Int
    let isCompleted: Bool
    let actionTitle: String
    let onAction: (LearningInteractionResult) -> Void

    var body: some View {
        FoundationCard {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                header

                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Text(item.title)
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(item.summary)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                if item.isReview && !revealsReviewMaterial {
                    recallBoundary
                } else {
                    ContentUnitRenderer(item: item)

                    Divider()

                    ContentMetadataView(item: item)
                }

                Label(item.recommendationReason, systemImage: item.isReview ? "clock.arrow.circlepath" : "sparkles")
                    .font(AppTypography.supporting)
                    .foregroundStyle(AppColor.accent)
                    .fixedSize(horizontal: false, vertical: true)

                if let interaction = primaryInteraction {
                    Divider()

                    if item.interactions.count > 1 {
                        interactionPicker
                    }

                    interactionSection(interaction)
                }

                Spacer(minLength: AppSpacing.small)

                Button(primaryButtonTitle, action: handlePrimaryAction)
                    .buttonStyle(.primaryAction)
                    .disabled(!canSubmit)
                    .accessibilityHint(
                        needsObjectiveEvaluation && evaluatedResult == nil
                            ? "Checks your response"
                            : position == total
                                ? "Completes this learning session"
                                : "Moves to the next card"
                    )
            }
            .frame(maxWidth: .infinity, minHeight: 430, alignment: .topLeading)
        }
        .overlay(alignment: .topTrailing) {
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppColor.success)
                    .padding(AppSpacing.xLarge)
                    .accessibilityLabel("Completed")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Card \(position) of \(total): \(item.title)")
        .task {
            selectedInteractionID = selectedInteractionID ?? item.preferredInteraction?.id
        }
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    categoryLabel
                    durationLabel
                }
            } else {
                HStack(alignment: .center, spacing: AppSpacing.small) {
                    categoryLabel

                    Spacer(minLength: AppSpacing.small)

                    durationLabel
                }
            }
        }
    }

    private var categoryLabel: some View {
        Text(item.categoryName)
            .font(AppTypography.caption)
            .foregroundStyle(AppColor.accent)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(AppColor.accent.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }

    private var durationLabel: some View {
        Label("\(item.estimatedMinutes) min", systemImage: "clock")
            .font(AppTypography.caption)
            .foregroundStyle(AppColor.textSecondary)
            .monospacedDigit()
    }

    private var primaryInteraction: InteractionSpec? {
        if let selectedInteractionID,
           let selected = item.interactions.first(where: { $0.id == selectedInteractionID }) {
            return selected
        }
        return item.preferredInteraction
    }

    private var interactionPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Choose your practice")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)

            ScrollView(.horizontal) {
                HStack(spacing: AppSpacing.small) {
                    ForEach(item.interactions) { interaction in
                        let isSelected = primaryInteraction?.id == interaction.id

                        Button {
                            selectedInteractionID = interaction.id
                            responseText = ""
                            selectedOptions = []
                            evaluatedResult = nil
                            confidence = .medium
                            startedAt = .now
                        } label: {
                            Label(interaction.kind.displayName, systemImage: interaction.kind.systemImage)
                                .font(AppTypography.caption)
                                .foregroundStyle(isSelected ? AppColor.onAccent : AppColor.textPrimary)
                                .padding(.horizontal, AppSpacing.medium)
                                .frame(minHeight: 44)
                                .background(isSelected ? AppColor.accent : AppColor.background)
                                .clipShape(Capsule())
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityValue(isSelected ? "Selected" : "Not selected")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var needsObjectiveEvaluation: Bool {
        guard let interaction = primaryInteraction else {
            return false
        }

        return interaction.evaluationKind == .exactMatch
            || interaction.evaluationKind == .choice
    }

    private var canSubmit: Bool {
        guard let interaction = primaryInteraction, interaction.isRequired else {
            return true
        }

        switch interaction.responseKind {
        case .none:
            return true
        case .singleChoice, .multipleChoice:
            return !selectedOptions.isEmpty
        case .text, .number, .code, .measurement:
            return !responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var primaryButtonTitle: String {
        if item.isReview && !revealsReviewMaterial {
            return needsObjectiveEvaluation ? "Check and reveal" : "Reveal and compare"
        }

        if needsObjectiveEvaluation && evaluatedResult == nil {
            return "Check answer"
        }

        return actionTitle
    }

    private var recallBoundary: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Label("RECALL FIRST", systemImage: "brain.head.profile.fill")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.accent)

            Text("The reference is intentionally hidden")
                .font(AppTypography.cardTitle)

            Text("Write what you can reconstruct below. Revealing the material will not erase your first response.")
                .font(AppTypography.supporting)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.large)
        .background(AppColor.accent.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func interactionSection(_ interaction: InteractionSpec) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: interaction.kind.systemImage)
                    .foregroundStyle(AppColor.accent)

                Text("Practice")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.accent)

                Spacer()

                Text("\(interaction.estimatedMinutes) min")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Text(interaction.prompt)
                .font(AppTypography.cardTitle)
                .fixedSize(horizontal: false, vertical: true)

            responseControl(for: interaction)

            if interaction.responseKind != .none {
                confidencePicker
            }

            if let evaluatedResult {
                evaluationFeedback(evaluatedResult)
            }
        }
        .padding(AppSpacing.large)
        .background(AppColor.accent.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }

    private var confidencePicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("How available does this feel?")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)

            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: AppSpacing.small) {
                    ForEach(AttemptConfidence.allCases) { option in
                        let isSelected = confidence == option

                        Button {
                            confidence = option
                        } label: {
                            HStack(spacing: AppSpacing.medium) {
                                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(AppColor.accent)

                                Text(option.title)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColor.textPrimary)

                                Spacer(minLength: AppSpacing.small)
                            }
                            .padding(.horizontal, AppSpacing.medium)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .background(isSelected ? AppColor.accent.opacity(0.10) : AppColor.background)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.title)
                        .accessibilityValue(isSelected ? "Selected" : "Not selected")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Confidence")
            } else {
                Picker("Confidence", selection: $confidence) {
                    ForEach(AttemptConfidence.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    @ViewBuilder
    private func responseControl(for interaction: InteractionSpec) -> some View {
        switch interaction.responseKind {
        case .none:
            Label("Pause for a moment before continuing.", systemImage: "wind")
                .font(AppTypography.supporting)
                .foregroundStyle(AppColor.textSecondary)
        case .text:
            responseField(
                title: "Your reflection",
                prompt: "Write a thought in your own words",
                keyboard: .default
            )
        case .code:
            responseField(
                title: "Your solution",
                prompt: "Write or describe your solution",
                keyboard: .asciiCapable
            )
        case .number, .measurement:
            responseField(
                title: "Your answer",
                prompt: interaction.responseKind == .number ? "Enter a number" : "Record what you observed",
                keyboard: interaction.responseKind == .number ? .decimalPad : .default
            )
        case .singleChoice:
            choiceOptions(interaction.options, allowsMultiple: false)
        case .multipleChoice:
            choiceOptions(interaction.options, allowsMultiple: true)
        }
    }

    private func responseField(
        title: String,
        prompt: String,
        keyboard: UIKeyboardType
    ) -> some View {
        TextField(prompt, text: $responseText, axis: .vertical)
            .font(AppTypography.body)
            .lineLimit(2...5)
            .textFieldStyle(.plain)
            .keyboardType(keyboard)
            .padding(AppSpacing.medium)
            .background(AppColor.background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                    .stroke(AppColor.separator.opacity(0.7), lineWidth: 0.5)
            }
            .accessibilityLabel(title)
    }

    private func choiceOptions(
        _ options: [String],
        allowsMultiple: Bool
    ) -> some View {
        VStack(spacing: AppSpacing.small) {
            ForEach(options, id: \.self) { option in
                Button {
                    if allowsMultiple {
                        if selectedOptions.contains(option) {
                            selectedOptions.remove(option)
                        } else {
                            selectedOptions.insert(option)
                        }
                    } else {
                        selectedOptions = [option]
                    }
                    evaluatedResult = nil
                } label: {
                    HStack(spacing: AppSpacing.medium) {
                        Image(
                            systemName: selectedOptions.contains(option)
                                ? allowsMultiple ? "checkmark.square.fill" : "largecircle.fill.circle"
                                : allowsMultiple ? "square" : "circle"
                        )
                        .foregroundStyle(
                            selectedOptions.contains(option)
                                ? AppColor.accent
                                : AppColor.textSecondary
                        )

                        Text(option)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textPrimary)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                    .padding(AppSpacing.medium)
                    .background(AppColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(
                    selectedOptions.contains(option) ? .isSelected : []
                )
            }
        }
    }

    private func evaluationFeedback(_ result: LearningInteractionResult) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            Image(
                systemName: result.isCorrect == true
                    ? "checkmark.circle.fill"
                    : "arrow.trianglehead.2.clockwise.rotate.90.circle.fill"
            )
            .foregroundStyle(result.isCorrect == true ? AppColor.success : AppColor.accent)

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(result.isCorrect == true ? "That’s right" : "Good attempt")
                    .font(AppTypography.cardTitle)

                Text(feedbackMessage)
                    .font(AppTypography.supporting)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var feedbackMessage: String {
        guard let primaryInteraction else {
            return ""
        }

        if evaluatedResult?.isCorrect == true {
            return "Continue while the idea is still active in memory."
        }

        if let expected = primaryInteraction.expectedResponse, !expected.isEmpty {
            return "The expected answer is \(expected). Review the reasoning, then continue."
        }

        return "Use the material above to compare your reasoning before continuing."
    }

    private func handlePrimaryAction() {
        let result = makeResult()

        if item.isReview && !revealsReviewMaterial {
            if needsObjectiveEvaluation {
                evaluatedResult = result
            }
            withAnimation(AppMotion.session(reduceMotion: reduceMotion)) {
                revealsReviewMaterial = true
            }
            return
        }

        if needsObjectiveEvaluation && evaluatedResult == nil {
            evaluatedResult = result
            return
        }

        onAction(evaluatedResult ?? result)
    }

    private func makeResult() -> LearningInteractionResult {
        let completedAt = Date.now

        guard let interaction = primaryInteraction else {
            return LearningInteractionResult(
                interactionID: nil,
                interactionKind: nil,
                response: "",
                isCorrect: nil,
                confidence: confidence,
                startedAt: startedAt,
                completedAt: completedAt,
                durationSeconds: completedAt.timeIntervalSince(startedAt),
                difficulty: item.difficulty
            )
        }

        let response: String
        switch interaction.responseKind {
        case .singleChoice, .multipleChoice:
            response = selectedOptions.sorted().joined(separator: ", ")
        case .none:
            response = ""
        case .text, .number, .code, .measurement:
            response = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let correctness: Bool?
        if needsObjectiveEvaluation, let expected = interaction.expectedResponse {
            correctness = normalized(response) == normalized(expected)
        } else {
            correctness = nil
        }

        return LearningInteractionResult(
            interactionID: interaction.id,
            interactionKind: interaction.kind,
            response: response,
            isCorrect: correctness,
            confidence: confidence,
            startedAt: startedAt,
            completedAt: completedAt,
            durationSeconds: completedAt.timeIntervalSince(startedAt),
            difficulty: item.difficulty
        )
    }

    private func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: " ", with: "")
    }
}

private extension InteractionKind {
    var displayName: String {
        switch self {
        case .learn: "Learn"
        case .reflect: "Reflect"
        case .discuss: "Discuss"
        case .solve: "Solve"
        case .prove: "Prove"
        case .practice: "Practice"
        case .apply: "Apply"
        case .observe: "Observe"
        case .explain: "Explain"
        case .recall: "Recall"
        case .quiz: "Quiz"
        case .build: "Build"
        case .track: "Track"
        }
    }

    var systemImage: String {
        switch self {
        case .learn: "book.closed.fill"
        case .reflect: "sparkles"
        case .discuss: "bubble.left.and.bubble.right.fill"
        case .solve: "function"
        case .prove: "checkmark.seal.fill"
        case .practice: "figure.mind.and.body"
        case .apply: "hammer.fill"
        case .observe: "eye.fill"
        case .explain: "quote.bubble.fill"
        case .recall: "brain.head.profile.fill"
        case .quiz: "questionmark.circle.fill"
        case .build: "wrench.and.screwdriver.fill"
        case .track: "chart.line.uptrend.xyaxis"
        }
    }
}

#Preview {
    LearningCardShell(
        item: LearningSessionItem(
            id: UUID(),
            title: "The boundary of control",
            summary: "A reflection on directing effort toward choices rather than outcomes.",
            categoryName: "Philosophy",
            kind: .principle,
            difficulty: .introductory,
            estimatedMinutes: 4,
            blocks: [
                ContentBlockSpec(
                    kind: .paragraph,
                    order: 0,
                    content: "Some outcomes depend on our choices; others also depend on circumstances and other people."
                ),
                ContentBlockSpec(
                    kind: .callout,
                    order: 1,
                    content: "Spend effort where a deliberate choice is still possible."
                )
            ],
            source: ContentSource(
                title: "Evolve Stage 6 sample",
                creator: "Evolve Editorial",
                license: "Internal sample"
            )
        ),
        position: 1,
        total: 3,
        isCompleted: false,
        actionTitle: "Next card"
    ) { _ in }
    .padding()
    .background(AppColor.groupedBackground)
}
