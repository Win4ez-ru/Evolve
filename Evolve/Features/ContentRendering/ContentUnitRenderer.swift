import SwiftUI

struct ContentUnitRenderer: View {
    let item: LearningSessionItem

    @ViewBuilder
    var body: some View {
        switch ContentRendererResolver.unitRenderer(for: item.kind) {
        case .concept:
            ConceptContentRenderer(blocks: item.blocks)
        case .principle:
            PrincipleContentRenderer(blocks: item.blocks)
        case .dilemma:
            DilemmaContentRenderer(blocks: item.blocks)
        case .problem:
            ProblemContentRenderer(blocks: item.blocks)
        case .workedExample:
            WorkedExampleContentRenderer(blocks: item.blocks)
        case .standard:
            StandardContentRenderer(
                kindName: item.kindName,
                blocks: item.blocks
            )
        }
    }
}

#Preview("Principle renderer") {
    ContentUnitRenderer(
        item: LearningSessionItem(
            id: MVPContentFixtures.philosophyUnit.id,
            title: MVPContentFixtures.philosophyUnit.title,
            summary: MVPContentFixtures.philosophyUnit.summary,
            categoryName: "Philosophy",
            kind: MVPContentFixtures.philosophyUnit.kind,
            difficulty: MVPContentFixtures.philosophyUnit.difficulty,
            estimatedMinutes: MVPContentFixtures.philosophyUnit.estimatedMinutes,
            blocks: MVPContentFixtures.philosophyUnit.blocks,
            source: MVPContentFixtures.philosophyUnit.source
        )
    )
    .padding()
    .background(AppColor.groupedBackground)
}
