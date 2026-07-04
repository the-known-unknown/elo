import AppKit

/// A keyboard shortcut: a virtual key code plus modifier flags.
///
/// `keyCode`/`modifierFlags` are what we need to register a global hotkey (via
/// Carbon); `keyLabel` is captured for display.
struct Hotkey: Equatable {
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

// MARK: - Codable

// `NSEvent.ModifierFlags` isn't `Codable`, so we persist its raw `UInt` value.
extension Hotkey: Codable {
    private enum CodingKeys: String, CodingKey {
        case keyCode, modifierFlags, keyLabel
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyCode = try container.decode(UInt16.self, forKey: .keyCode)
        modifierFlags = NSEvent.ModifierFlags(
            rawValue: try container.decode(UInt.self, forKey: .modifierFlags))
        keyLabel = try container.decode(String.self, forKey: .keyLabel)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyCode, forKey: .keyCode)
        try container.encode(modifierFlags.rawValue, forKey: .modifierFlags)
        try container.encode(keyLabel, forKey: .keyLabel)
    }
}
