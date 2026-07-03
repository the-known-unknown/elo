import SwiftUI

/// The "Application" settings tab.
///
/// UI only for now: everything is backed by local `@State` and stubbed actions.
/// Persistence, the real hotkey recorder, and live permission status will be
/// wired in later steps.
struct ApplicationSettingsView: View {
    @State private var launchAtLogin = false
    @State private var permissionsGranted = false
    @State private var functions: [FunctionItem] = FunctionItem.defaults

    /// The function currently being edited (drives the modal editor).
    @State private var editingFunction: FunctionItem?

    private let hotkeyDisplay = "⌘⌥E"

    var body: some View {
        Form {
            generalSection
            hotkeySection
            functionsSection
            accessibilitySection
        }
        .formStyle(.grouped)
        .sheet(item: $editingFunction) { function in
            FunctionEditorView(function: function) { updated in
                save(updated)
            } onCancel: {
                editingFunction = nil
            }
        }
    }

    // MARK: - General

    private var generalSection: some View {
        Section {
            Toggle("Launch Elo at login", isOn: $launchAtLogin)
        } header: {
            Text("General")
        }
    }

    // MARK: - Hotkey

    private var hotkeySection: some View {
        Section {
            LabeledContent("Invoke Elo") {
                // Placeholder for the real KeyboardShortcuts recorder (added later).
                Button(action: {}) {
                    Text(hotkeyDisplay)
                        .font(.system(.body, design: .monospaced))
                }
                .buttonStyle(.bordered)
                .help("Shortcut recording coming soon")
            }
        } header: {
            Text("Hotkey")
        } footer: {
            Text("This helps you invoke Elo (default: ⌘⌥E).")
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

            if functions.count < FunctionItem.maxCount {
                Button(action: addFunction) {
                    Label("Add function", systemImage: "plus")
                }
            }
        } header: {
            Text("Functions")
        } footer: {
            Text("Up to \(FunctionItem.maxCount) functions appear in the Elo menu.")
        }
    }

    private func addFunction() {
        let new = FunctionItem.empty()
        functions.append(new)
        editingFunction = new
    }

    /// Writes an edited function back into the list (matched by id) and closes the editor.
    private func save(_ function: FunctionItem) {
        if let index = functions.firstIndex(where: { $0.id == function.id }) {
            functions[index] = function
        }
        editingFunction = nil
    }

    // MARK: - Accessibility

    private var accessibilitySection: some View {
        Section {
            HStack(spacing: 8) {
                Image(
                    systemName: permissionsGranted
                        ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
                .foregroundStyle(permissionsGranted ? Color.green : Color.orange)
                Text(permissionsGranted ? "Permissions granted" : "Permissions not granted")
                Spacer()
                if !permissionsGranted {
                    Button("Grant") { permissionsGranted = true }
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
    let function: FunctionItem
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

    private let original: FunctionItem
    private let onSave: (FunctionItem) -> Void
    private let onCancel: () -> Void

    init(
        function: FunctionItem,
        onSave: @escaping (FunctionItem) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.original = function
        self.onSave = onSave
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
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Prompt")
                TextEditor(text: $prompt)
                    .font(.body)
                    .frame(minHeight: 160)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.quaternary, lineWidth: 1)
                    )
            }

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    var updated = original
                    updated.label = label
                    updated.prompt = prompt
                    onSave(updated)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 460, height: 380)
    }
}

// MARK: - UI-local model

/// Lightweight, UI-only model for a function. Will be replaced by the persisted
/// settings model in a later step.
private struct FunctionItem: Identifiable {
    let id = UUID()
    var label: String
    var prompt: String

    static let maxCount = 4

    static func empty() -> FunctionItem {
        FunctionItem(label: "", prompt: "")
    }

    static let defaults: [FunctionItem] = [
        FunctionItem(
            label: "Improve writing",
            prompt:
                "Can you improve this text, fix typos and improve the grammar to make it sound more polished?"
        ),
        FunctionItem(
            label: "Make Concise",
            prompt: "Make this text more concise, without losing important detail"
        ),
        FunctionItem(
            label: "Itemize",
            prompt:
                "I would like you to rewrite this text as a simple bulleted list, without losing important detail. Ensure each bullet is concise. Feel free to organize this into a group of categories with sub-bullets in each (if applicable)"
        ),
    ]
}
