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
        [weak self] function, selectedText in
        self?.handleFunctionSelected(function, selectedText: selectedText)
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
    }

    // MARK: - Hotkey / action menu

    private func handleHotkey() {
        // Capture the selection while the source app is still frontmost (this waits
        // for the hotkey modifiers to release first), then show the function menu.
        SelectionReader.copySelectedText { [weak self] selectedText in
            guard let self else { return }
            log("Hotkey pressed. Selected text: \(preview(selectedText)).")
            actionMenuController.show(
                functions: settingsStore.settings.application.functions,
                selectedText: selectedText
            )
        }
    }

    private func handleFunctionSelected(_ function: Function, selectedText: String?) {
        log("Function \"\(function.label)\" chosen. Text: \(preview(selectedText)).")
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
