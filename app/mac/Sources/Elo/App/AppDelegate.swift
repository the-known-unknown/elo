import AppKit

/// App entry point wiring. Stripped down to the bare menu-bar agent shell so we
/// can rebuild functionality one problem at a time.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController!
    private let aboutWindowController = AboutWindowController()
    private let settingsWindowController = SettingsWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = StatusItemController(
            onSettings: handleSettings,
            onAbout: handleAbout,
            onQuit: handleQuit
        )

        log("Launched (shell only).")
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
