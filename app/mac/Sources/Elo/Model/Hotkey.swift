import AppKit

/// A keyboard shortcut: a virtual key code plus modifier flags.
///
/// `keyCode`/`modifierFlags` are what we need to register a global hotkey (via
/// Carbon); `keyLabel` is captured for display.
struct Hotkey {
    var keyCode: UInt16
    var modifierFlags: NSEvent.ModifierFlags
    var keyLabel: String

    /// The default shortcut: ⌘⌥E (E is virtual key code 14).
    static let `default` = Hotkey(keyCode: 14, modifierFlags: [.command, .option], keyLabel: "E")

    /// Human-readable form, e.g. "⌘⌥E" (modifier order matches macOS convention).
    var displayString: String {
        var symbols = ""
        if modifierFlags.contains(.control) { symbols += "⌃" }
        if modifierFlags.contains(.option) { symbols += "⌥" }
        if modifierFlags.contains(.shift) { symbols += "⇧" }
        if modifierFlags.contains(.command) { symbols += "⌘" }
        return symbols + keyLabel
    }
}
