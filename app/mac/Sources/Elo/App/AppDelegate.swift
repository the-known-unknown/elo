import AppKit
import Combine

/// App entry point wiring. Stripped down to the bare menu-bar agent shell so we
/// can rebuild functionality one problem at a time.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController!
    private let aboutWindowController = AboutWindowController()
    private let hotkeyStore = HotkeyStore()
    private lazy var settingsWindowController = SettingsWindowController(hotkeyStore: hotkeyStore)

    private lazy var hotkeyManager = HotkeyManager { [weak self] in
        self?.handleHotkey()
    }
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = StatusItemController(
            onSettings: handleSettings,
            onAbout: handleAbout,
            onQuit: handleQuit
        )

        // Register the global hotkey now, and re-register whenever it changes.
        // (`$hotkey` emits its current value immediately on subscription.)
        hotkeyStore.$hotkey
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
