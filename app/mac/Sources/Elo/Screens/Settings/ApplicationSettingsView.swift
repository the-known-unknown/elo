import AppKit
import Combine
import SwiftUI

/// The "Application" settings tab.
///
/// Persisted settings (hotkey, functions) flow through `settingsStore`.
/// Launch-at-login and Accessibility are live OS state, read from their managers.
struct ApplicationSettingsView: View {
    /// Single source of truth for persisted settings (hotkey + functions).
    @ObservedObject var settingsStore: SettingsStore

    /// Mirrors the real login-item state; explicitly hydrated from
    /// `LaunchAtLoginManager` on open and after each change.
    @State private var launchAtLogin = LaunchAtLoginManager.isEnabled

    /// Live Accessibility permission status (re-hydrated when the window opens).
    @State private var accessibilityGranted = AccessibilityManager.isTrusted

    /// The function currently being edited (drives the modal editor).
    @State private var editingFunction: Function?

    var body: some View {
        Form {
            generalSection
            hotkeySection
            functionsSection
            accessibilitySection
        }
        .formStyle(.grouped)
        .sheet(item: $editingFunction) { function in
            FunctionEditorView(
                function: function,
                onSave: { save($0) },
                onDelete: { delete(function) },
                onCancel: { editingFunction = nil }
            )
        }
        // Re-hydrate live state (e.g. launch-at-login) each time the window is
        // shown. The window is reused, so `onAppear` only fires once — becoming
        // key is our signal that Settings was (re)opened.
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) {
            _ in
            launchAtLogin = LaunchAtLoginManager.isEnabled
            accessibilityGranted = AccessibilityManager.isTrusted
        }
        // macOS sends no notification when Accessibility is granted, so poll the
        // live status while Settings is open (cheap; picks up the grant without
        // needing the window to regain focus).
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            accessibilityGranted = AccessibilityManager.isTrusted
        }
    }

    // MARK: - General

    private var generalSection: some View {
        Section {
            Toggle("Launch Elo on login", isOn: launchAtLoginBinding)
        } header: {
            Text("General")
        }
    }

    /// The toggle reflects `launchAtLogin`; on user change we apply the setting
    /// and then set the state to the actual result (snaps back if it failed).
    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLogin },
            set: { isOn in
                let ok = LaunchAtLoginManager.setEnabled(isOn)
                launchAtLogin = LaunchAtLoginManager.isEnabled
                log(
                    "Launch at login \(launchAtLogin ? "enabled" : "disabled")\(ok ? "" : " (failed)")."
                )
            }
        )
    }

    // MARK: - Hotkey

    private var hotkeySection: some View {
        Section {
            LabeledContent("Invoke Elo") {
                HotkeyRecorderView(hotkey: $settingsStore.settings.application.hotkey)
            }
        } header: {
            Text("Hotkey")
        }
    }

    // MARK: - Functions

    private var functionsSection: some View {
        Section {
            ForEach(Array(functions.enumerated()), id: \.element.id) { index, function in
                FunctionRowView(number: index + 1, function: function) {
                    editingFunction = function
                }
            }

            if functions.count < Function.maxCount {
                Button(action: addFunction) {
                    Label("Add function", systemImage: "plus")
                }
            }
        } header: {
            Text("Functions")
        } footer: {
            Text("Up to \(Function.maxCount) functions appear in the Elo menu.")
        }
    }

    /// The persisted functions (lives in the settings store).
    private var functions: [Function] {
        settingsStore.settings.application.functions
    }

    private func addFunction() {
        let new = Function.empty()
        settingsStore.settings.application.functions.append(new)
        editingFunction = new
    }

    /// Writes an edited function back into the store (matched by id) and closes the editor.
    private func save(_ function: Function) {
        if let index = settingsStore.settings.application.functions.firstIndex(where: {
            $0.id == function.id
        }) {
            settingsStore.settings.application.functions[index] = function
        }
        editingFunction = nil
    }

    /// Removes a function from the store and closes the editor.
    private func delete(_ function: Function) {
        settingsStore.settings.application.functions.removeAll { $0.id == function.id }
        editingFunction = nil
    }

    // MARK: - Accessibility

    private var accessibilitySection: some View {
        Section {
            HStack(spacing: 8) {
                Image(
                    systemName: accessibilityGranted
                        ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
                .foregroundStyle(accessibilityGranted ? Color.green : Color.orange)
                Text(accessibilityGranted ? "Permissions granted" : "Permissions not granted")
                Spacer()
                if !accessibilityGranted {
                    Button("Grant") {
                        AccessibilityManager.requestAccess()
                    }
                }
            }
        } header: {
            Text("Accessibility")
        } footer: {
            Text("Elo needs Accessibility access to read selected text.")
        }
    }
}

// MARK: - Function row (view state)

/// A single function as shown in the list: number, label, prompt preview, chevron.
/// The whole row is tappable and opens the editor.
private struct FunctionRowView: View {
    let number: Int
    let function: Function
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text("\(number)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(.quaternary))

                VStack(alignment: .leading, spacing: 2) {
                    Text(function.label.isEmpty ? "Untitled" : function.label)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(function.prompt)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}

// MARK: - Function editor (edit state, modal)

/// Modal editor for a function: label field, prompt text area, and Save.
private struct FunctionEditorView: View {
    @State private var label: String
    @State private var prompt: String

    private let original: Function
    private let onSave: (Function) -> Void
    private let onDelete: () -> Void
    private let onCancel: () -> Void

    private let maxWords = 1000

    private var wordCount: Int {
        prompt.split(whereSeparator: { $0.isWhitespace }).count
    }

    private var isOverLimit: Bool { wordCount > maxWords }

    private var trimmedLabel: String { label.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedPrompt: String { prompt.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Save is enabled only when both fields have real text and we're within the limit.
    private var isValid: Bool { !trimmedLabel.isEmpty && !trimmedPrompt.isEmpty && !isOverLimit }

    init(
        function: Function,
        onSave: @escaping (Function) -> Void,
        onDelete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.original = function
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        _label = State(initialValue: function.label)
        _prompt = State(initialValue: function.prompt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Label")
                TextField("", text: $label)
                    .textFieldStyle(.roundedBorder)
                if trimmedLabel.isEmpty {
                    Text("Label is required.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Prompt")
                TextEditor(text: $prompt)
                    .font(.body)
                    .frame(minHeight: 160)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                isOverLimit ? Color.red : Color(.quaternaryLabelColor), lineWidth: 1
                            )
                    )
                HStack {
                    if trimmedPrompt.isEmpty {
                        Text("Prompt is required.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(wordCount) / \(maxWords) words")
                        .font(.caption)
                        .foregroundStyle(isOverLimit ? Color.red : Color.secondary)
                }
            }

            HStack {
                Button("Delete", role: .destructive, action: onDelete)
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    var updated = original
                    updated.label = trimmedLabel
                    updated.prompt = trimmedPrompt
                    onSave(updated)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding(20)
        .frame(width: 460, height: 400)
    }
}
