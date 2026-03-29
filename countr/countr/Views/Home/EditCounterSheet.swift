import SwiftUI
import SwiftData

struct EditCounterSheet: View {
    @Bindable var counter: Counter
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(HapticService.self) private var haptics

    @Query(sort: \CounterGroup.order) private var groups: [CounterGroup]
    @Query(sort: \Counter.order) private var allCounters: [Counter]

    @State private var name: String = ""
    @State private var resetMode: ResetMode = .manual
    @State private var stepValue: String = "1"
    @State private var goalText: String = ""
    @State private var color: CounterColor = .blue
    @State private var selectedGroup: CounterGroup?
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Date()
    @State private var showNewGroupField: Bool = false
    @State private var newGroupName: String = ""
    @State private var showResetAlert: Bool = false
    @State private var showDeleteAlert: Bool = false

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
                Section("Reorder") {
                    Button("Move Up") { moveCounter(by: -1) }.disabled(counter.order == 0)
                    Button("Move Down") { moveCounter(by: 1) }.disabled(counter.order >= allCounters.count - 1)
                }
                Section {
                    Button("Reset to 0") { showResetAlert = true }.foregroundStyle(.orange)
                    Button("Delete Counter", role: .destructive) { showDeleteAlert = true }
                }
            }
            .navigationTitle("Edit Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Reset Counter?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) { counter.count = 0; haptics.mediumImpact() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This will set the count to 0.") }
            .alert("Delete Counter?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) { modelContext.delete(counter); dismiss() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This cannot be undone.") }
            .onAppear {
                name = counter.name
                resetMode = counter.resetMode
                stepValue = "\(counter.stepValue)"
                goalText = counter.goal.map { "\($0)" } ?? ""
                color = counter.color
                selectedGroup = counter.group
                reminderEnabled = counter.reminderTime != nil
                if let timeStr = counter.reminderTime {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    reminderTime = formatter.date(from: timeStr) ?? Date()
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

    private func saveChanges() {
        counter.name = name.trimmingCharacters(in: .whitespaces)
        counter.resetMode = resetMode
        counter.stepValue = max(1, Int(stepValue) ?? 1)
        counter.goal = goalText.isEmpty ? nil : Int(goalText)
        counter.color = color
        counter.group = selectedGroup
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        counter.reminderTime = reminderEnabled ? formatter.string(from: reminderTime) : nil
        haptics.lightImpact()
        NotificationService.cancelReminder(for: counter)
        if reminderEnabled {
            NotificationService.requestPermission()
            NotificationService.scheduleReminder(for: counter)
        }
        dismiss()
    }

    private func moveCounter(by offset: Int) {
        let sorted = allCounters.sorted { $0.order < $1.order }
        guard let currentIndex = sorted.firstIndex(where: { $0.id == counter.id }) else { return }
        let newIndex = currentIndex + offset
        guard newIndex >= 0, newIndex < sorted.count else { return }
        sorted[newIndex].order = currentIndex
        counter.order = newIndex
        haptics.lightImpact()
    }
}
