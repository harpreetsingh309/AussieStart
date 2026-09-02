import SwiftUI

/// Lets a Pro user pick when to be reminded about a single checklist task.
struct TaskReminderSheet: View {
    @Environment(UserPreferences.self) private var preferences
    @Environment(\.dismiss) private var dismiss

    let taskID: String
    let taskTitle: String

    @State private var date: Date
    @State private var saving = false
    @State private var permissionDenied = false

    private let store = TaskReminderStore.shared

    init(taskID: String, taskTitle: String) {
        self.taskID = taskID
        self.taskTitle = taskTitle
        let existing = TaskReminderStore.shared.date(for: taskID)
        _date = State(initialValue: existing ?? Self.defaultDate)
    }

    /// Tomorrow morning — the usual answer for "remind me about this job".
    private static var defaultDate: Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
        var comps = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        comps.hour = 9
        comps.minute = 0
        return calendar.date(from: comps) ?? tomorrow
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(taskTitle)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section {
                    DatePicker(
                        preferences.t("reminder.task_when"),
                        selection: $date,
                        in: Date.now...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } footer: {
                    Text(preferences.t("reminder.task_blurb"))
                }

                if permissionDenied {
                    Section {
                        Label(preferences.t("reminder.task_denied"), systemImage: "bell.slash.fill")
                            .foregroundStyle(AppTheme.danger)
                            .font(.footnote)
                    }
                }

                if store.hasReminder(for: taskID) {
                    Section {
                        Button(role: .destructive) {
                            store.clear(taskID)
                            dismiss()
                        } label: {
                            Label(preferences.t("reminder.task_remove"), systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(preferences.t("reminder.task_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(preferences.t("common.close")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(preferences.t("reminder.task_save")) { save() }
                        .disabled(saving)
                }
            }
        }
    }

    private func save() {
        saving = true
        let body = preferences.t("reminder.task_body")
        Task {
            let ok = await store.set(date, for: taskID, title: taskTitle, body: body)
            saving = false
            if ok {
                dismiss()
            } else {
                permissionDenied = true
            }
        }
    }
}
