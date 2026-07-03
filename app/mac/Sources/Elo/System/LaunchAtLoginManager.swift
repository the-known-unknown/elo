import Foundation
import ServiceManagement

/// Controls whether Elo launches automatically at login.
///
/// Backed by `SMAppService.mainApp` (macOS 13+), which registers the app itself
/// as a login item. This requires a real, signed `.app` bundle — it does not work
/// when running the bare binary via `swift run`.
enum LaunchAtLoginManager {
    /// Whether Elo is currently registered to launch at login.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Registers or unregisters Elo as a login item.
    /// Returns whether the resulting state matches what was requested.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        guard enabled != isEnabled else { return true }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            log(
                "LaunchAtLogin: \(enabled ? "register" : "unregister") failed: \(error.localizedDescription)"
            )
            return false
        }
    }
}
