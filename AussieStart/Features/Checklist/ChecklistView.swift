import SwiftUI
import SwiftData

struct ChecklistView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var completed: Set<String> = []

    private var catalog: ContentCatalog { ContentLoader.shared.catalog }
    private var progress: ProgressRepository { ProgressRepository(context: modelContext) }

    var body: some View {
        List {
            ForEach(catalog.checklists) { checklist in
                Section {
                    ForEach(checklist.tasks) { task in
                        Button {
                            progress.toggleTask(task.id)
                            reload()
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: completed.contains(task.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(completed.contains(task.id) ? AppTheme.brandGreen : .secondary)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .foregroundStyle(.primary)
                                        .strikethrough(completed.contains(task.id))
                                    if let articleID = task.articleID {
                                        NavigationLink("Open guide") {
                                            ArticleDetailView(articleID: articleID)
                                        }
                                        .font(.caption)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(checklist.title)
                        Text(checklist.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        let done = checklist.tasks.filter { completed.contains($0.id) }.count
                        Text("\(done)/\(checklist.tasks.count) done")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.brandGreen)
                    }
                }
            }
        }
        .navigationTitle("Checklists")
        .onAppear(perform: reload)
    }

    private func reload() {
        completed = progress.completedTaskIDs()
    }
}
