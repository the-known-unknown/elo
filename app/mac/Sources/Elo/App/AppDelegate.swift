import AppKit
import Combine

/// App entry point wiring. Stripped down to the bare menu-bar agent shell so we
/// can rebuild functionality one problem at a time.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController!
    private let aboutWindowController = AboutWindowController()
    private let settingsStore = SettingsStore()
    private lazy var settingsWindowController = SettingsWindowController(
        settingsStore: settingsStore)

    private lazy var hotkeyManager = HotkeyManager { [weak self] in
        self?.handleHotkey()
    }
    private lazy var actionMenuController = ActionMenuController {
        [weak self] function, selection in
        self?.handleFunctionSelected(function, selection: selection)
    }
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Provides standard editing shortcuts (copy/paste/etc.) in text fields.
        MainMenu.install()

        statusItemController = StatusItemController(
            onSettings: handleSettings,
            onAbout: handleAbout,
            onQuit: handleQuit
        )

        // Register the global hotkey now, and re-register whenever it changes.
        // (The publisher emits its current value immediately on subscription.)
        settingsStore.hotkeyPublisher
            .sink { [weak self] hotkey in
                self?.hotkeyManager.register(
                    keyCode: hotkey.keyCode, modifierFlags: hotkey.modifierFlags)
            }
            .store(in: &cancellables)

        log("Launched. Accessibility trusted: \(AccessibilityManager.isTrusted).")

        // Elo can't read selected text without Accessibility, so prompt for it
        // on launch if it hasn't been granted yet.
        if !AccessibilityManager.isTrusted {
            AccessibilityManager.requestAccess()
        }
    }

    // MARK: - Hotkey / action menu

    private func handleHotkey() {
        // Capture the selection while the source app is still frontmost (this waits
        // for the hotkey modifiers to release first), then show the function menu.
        SelectionReader.copySelection { [weak self] selection in
            guard let self else { return }
            actionMenuController.show(
                functions: settingsStore.settings.application.functions,
                selection: selection
            )
        }
    }

    private func handleFunctionSelected(_ function: Function, selection: Selection?) {
        log(
            "Function \"\(function.label)\" chosen | editable=\(selection?.isEditable ?? false) | text: \(preview(selection?.text))."
        )
    }

    private func preview(_ text: String?) -> String {
        guard let text, !text.isEmpty else { return "<none>" }
        let oneLine = text.replacingOccurrences(of: "\n", with: " ")
        return oneLine.count > 80 ? "\"\(oneLine.prefix(80))…\"" : "\"\(oneLine)\""
    }

    // MARK: - Menu handlers

    private func handleSettings() {
        log("Opening Settings window.")
        settingsWindowController.show()
    }

    private func handleAbout() {
        log("Opening About window.")
        aboutWindowController.show()
    }

    private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
}
