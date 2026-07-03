import AppKit

/// App entry point wiring. Stripped down to the bare menu-bar agent shell so we
/// can rebuild functionality one problem at a time.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController!
    private let aboutWindowController = AboutWindowController()
    private let settingsWindowController = SettingsWindowController()

    private lazy var hotkeyManager = HotkeyManager { [weak self] in
        self?.handleHotkey()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = StatusItemController(
            onSettings: handleSettings,
            onAbout: handleAbout,
            onQuit: handleQuit
        )

        // Register the (default, for now) global hotkey.
        let hotkey = Hotkey.default
        hotkeyManager.register(keyCode: hotkey.keyCode, modifierFlags: hotkey.modifierFlags)

        log("Launched.")
    }

    // MARK: - Hotkey

    private func handleHotkey() {
        log("Elo 👋, at your service!")
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
