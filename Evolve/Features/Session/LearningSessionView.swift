import SwiftUI

struct LearningSessionView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var session: LearningSessionState
    @State private var visibleItemID: UUID?
    @State private var showsStopConfirmation = false

    private let onDismiss: () -> Void

    init(plan: LearningSessionPlan, onDismiss: @escaping () -> Void) {
        let initialState = LearningSessionState(plan: plan)
        _session = State(initialValue: initialState)
        _visibleItemID = State(initialValue: initialState.currentItemID)
        self.onDismiss = onDismiss
    }

    var body: some View {
        Group {
            if session.phase == .active {
                activeSession
                    .transition(.opacity)
            } else {
                SessionStopStateView(
                    phase: session.phase,
                    position: session.position,
                    total: session.plan.items.count,
                    completedCount: session.completedItemIDs.count,
                    onDismiss: onDismiss
                )
                .transition(.opacity)
            }
        }
        .background(AppColor.groupedBackground.ignoresSafeArea())
        .animation(
            AppMotion.session(reduceMotion: reduceMotion),
            value: session.phase
        )
        .confirmationDialog(
            "Stop this session?",
            isPresented: $showsStopConfirmation,
            titleVisibility: .visible
        ) {
            Button("Stop session", role: .destructive) {
                session.stop()
            }
            Button("Keep learning", role: .cancel) {}
        } message: {
            Text("Your place is shown before you return to Today.")
        }
    }

    private var activeSession: some View {
        VStack(spacing: 0) {
            SessionProgressHeader(
                position: session.position,
                total: session.plan.items.count,
                progress: session.progress
            ) {
                showsStopConfirmation = true
            }

            if dynamicTypeSize.isAccessibilitySize {
                accessibleCardList
            } else {
                pagedCardList
            }
        }
    }

    private var pagedCardList: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                cards(useViewportHeight: true)
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $visibleItemID)
        .onChange(of: visibleItemID, updateSelection)
        .accessibilityHint("Swipe vertically to move between the finite session cards")
    }

    private var accessibleCardList: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: AppSpacing.large) {
                cards(useViewportHeight: false)
            }
            .scrollTargetLayout()
            .padding(.vertical, AppSpacing.large)
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $visibleItemID)
        .onChange(of: visibleItemID, updateSelection)
        .accessibilityHint("Scroll vertically through the finite session cards")
    }

    @ViewBuilder
    private func cards(useViewportHeight: Bool) -> some View {
        ForEach(Array(session.plan.items.enumerated()), id: \.element.id) { index, item in
            card(item: item, index: index)
                .padding(.horizontal, AppSpacing.xLarge)
                .padding(.vertical, AppSpacing.large)
                .modifier(SessionPageHeightModifier(usesViewportHeight: useViewportHeight))
                .id(item.id)
        }
    }

    private func card(item: LearningSessionItem, index: Int) -> some View {
        LearningCardShell(
            item: item,
            position: index + 1,
            total: session.plan.items.count,
            isCompleted: session.completedItemIDs.contains(item.id),
            actionTitle: index == session.plan.items.count - 1 ? "Complete session" : "Next card"
        ) {
            advance()
        }
    }

    private func updateSelection(oldValue: UUID?, newValue: UUID?) {
        guard let newValue else {
            return
        }

        session.select(itemID: newValue)
    }

    private func advance() {
        let nextID = session.advance()
        guard let nextID else {
            return
        }

        withAnimation(AppMotion.session(reduceMotion: reduceMotion)) {
            visibleItemID = nextID
        }
    }
}

private struct SessionPageHeightModifier: ViewModifier {
    let usesViewportHeight: Bool

    func body(content: Content) -> some View {
        if usesViewportHeight {
            content.containerRelativeFrame(.vertical)
        } else {
            content
        }
    }
}

#Preview {
    LearningSessionView(
        plan: LearningSessionPlan(
            items: [
                LearningSessionItem(
                    id: UUID(),
                    title: "The boundary of control",
                    summary: "A reflection on directing effort toward choices rather than outcomes.",
                    categoryName: "Philosophy",
                    kindName: "Principle",
                    estimatedMinutes: 4
                ),
                LearningSessionItem(
                    id: UUID(),
                    title: "Retrieve before rereading",
                    summary: "Use an unaided attempt to reveal what is available from memory.",
                    categoryName: "Productivity & Learning",
                    kindName: "Technique",
                    estimatedMinutes: 5
                )
            ]
        )
    ) {}
}
