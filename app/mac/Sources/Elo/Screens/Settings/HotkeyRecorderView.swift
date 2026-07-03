import AppKit
import SwiftUI

/// A UI-only representation of a keyboard shortcut.
///
/// Will be folded into the persisted settings model later. `keyCode` and
/// `modifierFlags` are retained so we can register the global hotkey (via Carbon)
/// in a future step; `keyLabel` is captured for display.
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

/// A control that records a keyboard shortcut. Click to start recording, then
/// press a key combination that includes at least one modifier. Escape cancels.
struct HotkeyRecorderView: View {
    @Binding var hotkey: Hotkey

    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button(action: toggleRecording) {
            Text(isRecording ? "Type shortcut…" : hotkey.displayString)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 72)
        }
        .buttonStyle(.bordered)
        .help(isRecording ? "Press a shortcut, or Escape to cancel" : "Click to record a shortcut")
        .onDisappear(perform: stopRecording)
    }

    private func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        isRecording = true
        // Local monitor captures key events destined for this app while the
        // Settings window is key. Returning nil consumes the event.
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            handle(event)
            return nil
        }
    }

    private func handle(_ event: NSEvent) {
        // Escape (virtual key 53) cancels recording.
        if event.keyCode == 53 {
            stopRecording()
            return
        }

        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        guard !modifiers.isEmpty,
            let characters = event.charactersIgnoringModifiers,
            !characters.isEmpty
        else {
            // Require at least one modifier plus a key.
            NSSound.beep()
            return
        }

        hotkey = Hotkey(
            keyCode: event.keyCode,
            modifierFlags: modifiers,
            keyLabel: characters.uppercased()
        )
        stopRecording()
    }

    private func stopRecording() {
        isRecording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
