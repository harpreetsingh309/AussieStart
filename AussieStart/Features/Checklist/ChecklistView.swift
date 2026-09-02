import SwiftUI
import SwiftData

struct ChecklistView: View {
    @Environment(UserPreferences.self) private var preferences
    @Environment(StoreManager.self) private var store
    @Environment(\.modelContext) private var modelContext
    @State private var completed: Set<String> = []
    @State private var reminderTask: ChecklistTaskMeta?
    @State private var showPaywall = false

    private let reminders = TaskReminderStore.shared

    private var catalog: ContentCatalog { ContentLoader.shared.catalog }
    private var progress: ProgressRepository { ProgressRepository(context: modelContext) }

    var body: some View {
        List {
            ForEach(catalog.checklists.filter { $0.applies(to: preferences.persona) }) { checklist in
                Section {
                    ForEach(checklist.tasks) { task in
                        HStack(alignment: .top, spacing: 8) {
                        Button {
                            progress.toggleTask(task.id)
                            reload()
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: completed.contains(task.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(completed.contains(task.id) ? AppTheme.brandGreen : .secondary)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.localizedTitle(for: preferences.language))
                                        .foregroundStyle(.primary)
                                        .strikethrough(completed.contains(task.id))
                                    if let articleID = task.articleID {
                                        HStack {
                                            NavigationLink(preferences.t("checklist.open_guide")) {
                                                ArticleDetailView(articleID: articleID)
                                            }
                                            .font(.caption)
                                            if catalog.articles.first(where: { $0.id == articleID })?.requiresPro == true {
                                                ProBadge()
                                            }
                                        }
                                    }
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        reminderButton(for: task)
                        }
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(checklist.localizedTitle(for: preferences.language))
                        Text(checklist.localizedSubtitle(for: preferences.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        let done = checklist.tasks.filter { completed.contains($0.id) }.count
                        Text(preferences.t("checklist.done", done, checklist.tasks.count))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.brandGreen)
                    }
                }
            }
        }
        .navigationTitle(preferences.t("checklist.title"))
        .onAppear(perform: reload)
        .sheet(item: $reminderTask) { task in
            TaskReminderSheet(taskID: task.id, taskTitle: task.localizedTitle(for: preferences.language))
                .environment(preferences)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    @ViewBuilder
    private func reminderButton(for task: ChecklistTaskMeta) -> some View {
        let isSet = reminders.hasReminder(for: task.id)
        Button {
            if store.isPro {
                reminderTask = task
            } else {
                showPaywall = true
            }
        } label: {
            Image(systemName: isSet ? "bell.badge.fill" : "bell")
                .font(.footnote)
                .foregroundStyle(isSet ? AppTheme.brandGreen : .secondary)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            isSet ? preferences.t("reminder.task_edit_a11y") : preferences.t("reminder.task_add_a11y")
        )
    }

    private func reload() {
        completed = progress.completedTaskIDs()
        reminders.pruneExpired()
    }
}
