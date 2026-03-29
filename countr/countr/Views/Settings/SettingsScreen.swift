import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(HapticService.self) private var hapticService

    // Appearance
    @AppStorage("theme_mode") private var themeMode: String = "auto"

    // Defaults
    @AppStorage("default_reset_mode") private var defaultResetMode: String = ResetMode.manual.rawValue
    @AppStorage("default_step_value") private var defaultStepValue: Int = 1

    // Import/Export state
    @State private var exportURL: URL? = nil
    @State private var showExportError = false
    @State private var showImportPicker = false
    @State private var showImportConfirmation = false
    @State private var pendingImportData: Data? = nil
    @State private var importError: String? = nil
    @State private var showImportError = false
    @State private var showImportSuccess = false

    // App Icon
    @State private var selectedIcon: String = "default"

    private let appVersion: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }()

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Appearance
                Section("Appearance") {
                    appearancePicker
                    appIconPicker
                }

                // MARK: - Haptics
                Section("Feedback") {
                    @Bindable var haptics = hapticService
                    Toggle("Haptic Feedback", isOn: $haptics.isEnabled)
                }

                // MARK: - Defaults
                Section("Defaults") {
                    defaultResetModePicker
                    defaultStepValueRow
                }

                // MARK: - Backup
                Section("Backup") {
                    exportRow
                    importRow
                }

                // MARK: - About
                Section {
                    aboutRow
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        // Import file picker
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
        // Import confirmation alert
        .alert("Replace All Data?", isPresented: $showImportConfirmation) {
            Button("Cancel", role: .cancel) { pendingImportData = nil }
            Button("Replace", role: .destructive) {
                performImport()
            }
        } message: {
            Text("This will permanently replace all your counters, groups, and history with the data from the backup file.")
        }
        // Import error alert
        .alert("Import Failed", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "Unknown error.")
        }
        // Import success alert
        .alert("Import Successful", isPresented: $showImportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your backup has been restored.")
        }
    }

    // MARK: - Appearance Picker

    private var appearancePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color Scheme")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach([("auto", "Auto"), ("light", "Light"), ("dark", "Dark")], id: \.0) { value, label in
                    Button {
                        themeMode = value
                    } label: {
                        Text(label)
                            .font(.subheadline)
                            .fontWeight(themeMode == value ? .semibold : .regular)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(themeMode == value ? Color.accentColor : Color(.tertiarySystemFill))
                            .foregroundStyle(themeMode == value ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - App Icon Picker

    private var appIconPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("App Icon")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                iconOption(iconName: nil, label: "Default", key: "default")
                iconOption(iconName: "AppIcon-Dark", label: "Dark", key: "dark")
                iconOption(iconName: "AppIcon-Light", label: "Light", key: "light")
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            selectedIcon = UIApplication.shared.alternateIconName ?? "default"
        }
    }

    @ViewBuilder
    private func iconOption(iconName: String?, label: String, key: String) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "app.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.accentColor)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            selectedIcon == key ? Color.accentColor : Color.clear,
                            lineWidth: 2
                        )
                }
                .onTapGesture {
                    setAppIcon(iconName: iconName, key: key)
                }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func setAppIcon(iconName: String?, key: String) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if error == nil {
                selectedIcon = key
            }
        }
    }

    // MARK: - Default Reset Mode

    private var defaultResetModePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Default Reset Mode")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ResetMode.allCases) { mode in
                        Button {
                            defaultResetMode = mode.rawValue
                        } label: {
                            Text(mode.label)
                                .font(.subheadline)
                                .fontWeight(defaultResetMode == mode.rawValue ? .semibold : .regular)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(defaultResetMode == mode.rawValue ? Color.accentColor : Color(.tertiarySystemFill))
                                .foregroundStyle(defaultResetMode == mode.rawValue ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Default Step Value

    private var defaultStepValueRow: some View {
        HStack {
            Text("Default Step Value")
            Spacer()
            Stepper("\(defaultStepValue)", value: $defaultStepValue, in: 1...100)
        }
    }

    // MARK: - Export

    private var exportRow: some View {
        Button {
            generateExport()
        } label: {
            HStack {
                Label("Export Backup", systemImage: "square.and.arrow.up")
                Spacer()
                if let url = exportURL {
                    ShareLink(item: url, preview: SharePreview("countr-backup.countr.json")) {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .foregroundStyle(.primary)
        .sheet(isPresented: Binding(
            get: { exportURL != nil },
            set: { if !$0 { exportURL = nil } }
        )) {
            if let url = exportURL {
                ShareSheet(url: url)
            }
        }
    }

    private func generateExport() {
        do {
            let data = try BackupService.exportData(context: modelContext)
            let fileName = "countr-backup-\(formattedDate()).countr.json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try data.write(to: tempURL)
            exportURL = tempURL
        } catch {
            showExportError = true
        }
    }

    private func formattedDate() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    // MARK: - Import

    private var importRow: some View {
        Button {
            showImportPicker = true
        } label: {
            Label("Import Backup", systemImage: "square.and.arrow.down")
        }
        .foregroundStyle(.primary)
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                let data = try Data(contentsOf: url)
                pendingImportData = data
                showImportConfirmation = true
            } catch {
                importError = error.localizedDescription
                showImportError = true
            }
        case .failure(let error):
            importError = error.localizedDescription
            showImportError = true
        }
    }

    private func performImport() {
        guard let data = pendingImportData else { return }
        do {
            try BackupService.importData(from: data, context: modelContext)
            pendingImportData = nil
            showImportSuccess = true
        } catch {
            importError = error.localizedDescription
            showImportError = true
        }
    }

    // MARK: - About

    private var aboutRow: some View {
        VStack(spacing: 12) {
            Image(systemName: "app.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.accentColor)
            Text("countr")
                .font(.title2)
                .fontWeight(.bold)
            Text("Version \(appVersion)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

// MARK: - ShareSheet helper

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
