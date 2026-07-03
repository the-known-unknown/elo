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

    /// Requests access. This registers Elo in the Accessibility list (so it can
    /// be enabled) and shows the system "Open System Settings / Deny" prompt.
    static func requestAccess() {
        let options =
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
