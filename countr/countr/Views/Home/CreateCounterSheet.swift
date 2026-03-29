import SwiftUI
import SwiftData

struct CreateCounterSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(HapticService.self) private var haptics

    @Query(sort: \CounterGroup.order) private var groups: [CounterGroup]
    @Query(sort: \Counter.order) private var existingCounters: [Counter]

    @State private var name: String = ""
    @State private var resetMode: ResetMode = .manual
    @State private var stepValue: String = "1"
    @State private var goalText: String = ""
    @State private var color: CounterColor = .blue
    @State private var selectedGroup: CounterGroup?
    @State private var newGroupName: String = ""
    @State private var showNewGroupField: Bool = false
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = {
        var components = DateComponents()
        components.hour = 20
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") { TextField("Counter name", text: $name) }
                Section("Group") {
                    Picker("Group", selection: $selectedGroup) {
                        Text("None").tag(nil as CounterGroup?)
                        ForEach(groups) { group in Text(group.name).tag(group as CounterGroup?) }
                    }
                    Button("New Group") { showNewGroupField = true }
                    if showNewGroupField {
                        TextField("Group name", text: $newGroupName).onSubmit { createGroup() }
                    }
                }
                Section("Reset Mode") {
                    Picker("Reset Mode", selection: $resetMode) {
                        ForEach(ResetMode.allCases) { mode in Text(mode.label).tag(mode) }
                    }.pickerStyle(.segmented)
                }
                Section("Step Value") { TextField("Increment per tap", text: $stepValue).keyboardType(.numberPad) }
                Section("Goal (optional)") { TextField("Target count", text: $goalText).keyboardType(.numberPad) }
                Section("Color") { CounterColorPicker(selection: $color) }
                Section("Reminder") {
                    Toggle("Daily Reminder", isOn: $reminderEnabled)
                    if reminderEnabled { DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute) }
                }
            }
            .navigationTitle("New Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createCounter() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func createGroup() {
        guard !newGroupName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let group = CounterGroup(name: newGroupName, order: groups.count)
        modelContext.insert(group)
        selectedGroup = group
        showNewGroupField = false
        newGroupName = ""
    }

    private func createCounter() {
        let step = Int(stepValue) ?? 1
        let goal = goalText.isEmpty ? nil : Int(goalText)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let reminderTimeString: String? = reminderEnabled ? formatter.string(from: reminderTime) : nil

        let counter = Counter(
            name: name.trimmingCharacters(in: .whitespaces),
            resetMode: resetMode,
            stepValue: max(1, step),
            goal: goal,
            color: color,
            reminderTime: reminderTimeString,
            order: existingCounters.count,
            group: selectedGroup
        )
        modelContext.insert(counter)
        haptics.lightImpact()
        if reminderEnabled {
            NotificationService.requestPermission()
            NotificationService.scheduleReminder(for: counter)
        }
        dismiss()
    }
}
