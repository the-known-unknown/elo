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
