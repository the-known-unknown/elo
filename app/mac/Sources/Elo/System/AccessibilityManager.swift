import AppKit
import ApplicationServices

/// Wraps the macOS Accessibility (TCC) permission.
///
/// `isTrusted` is live OS state, not a saved setting — macOS does not notify us
/// when it changes, so callers re-read it (we poll while Settings is open).
enum AccessibilityManager {
    /// Whether the app is currently trusted for Accessibility.
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Opens System Settings → Privacy & Security → Accessibility.
    ///
    /// We deep-link here rather than using the `AXIsProcessTrustedWithOptions`
    /// system prompt: that prompt deactivates our Dock-less agent app, which makes
    /// the Settings window appear to vanish when it's dismissed.
    static func openSettings() {
        guard
            let url = URL(
                string:
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            )
        else { return }
        NSWorkspace.shared.open(url)
    }
}
