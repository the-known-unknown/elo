import AppKit

/// Reads the user's currently selected text from whatever app is frontmost.
///
/// Strategy: synthesize ⌘C, read the general pasteboard, then restore its previous
/// contents so we don't clobber the user's clipboard. Universal (native apps,
/// browsers, Electron) but requires Accessibility permission, since posting the
/// keystroke is a trusted operation.
///
/// The result is delivered asynchronously because we first wait for the hotkey's
/// modifier keys to be released — synthesizing ⌘C while ⌘/⌥ are still physically
/// held makes the system see ⌘⌥C (not Copy), so the copy silently fails.
enum SelectionReader {
    /// Copies the current selection and returns it on the main queue, or `nil` if
    /// nothing was copied (no selection, or the copy was blocked).
    static func copySelectedText(completion: @escaping (String?) -> Void) {
        waitForModifiersToClear {
            completion(performCopy())
        }
    }

    // MARK: - Wait for the triggering modifiers to be released

    private static func waitForModifiersToClear(
        attemptsRemaining: Int = 20, then action: @escaping () -> Void
    ) {
        let flags = CGEventSource.flagsState(.combinedSessionState)
        let modifiersHeld =
            flags.contains(.maskCommand)
            || flags.contains(.maskAlternate)
            || flags.contains(.maskControl)
            || flags.contains(.maskShift)

        if modifiersHeld, attemptsRemaining > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                waitForModifiersToClear(attemptsRemaining: attemptsRemaining - 1, then: action)
            }
        } else {
            action()
        }
    }

    // MARK: - Copy

    private static func performCopy() -> String? {
        let pasteboard = NSPasteboard.general
        let saved = snapshot(pasteboard)
        let previousChangeCount = pasteboard.changeCount

        synthesizeCommandC()

        // Wait briefly for the frontmost app to service the copy.
        let deadline = Date().addingTimeInterval(0.5)
        while pasteboard.changeCount == previousChangeCount, Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.02))
        }

        guard pasteboard.changeCount != previousChangeCount else {
            // The copy never registered — no selection, or the keystroke was
            // blocked (e.g. Accessibility not granted). Don't return stale text.
            log(
                "SelectionReader: copy did not register (accessibility trusted: \(AccessibilityManager.isTrusted); no selection, or keystroke blocked)."
            )
            restore(pasteboard, items: saved)
            return nil
        }

        let copied = pasteboard.string(forType: .string)
        restore(pasteboard, items: saved)

        let trimmed = copied?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty ?? true) ? nil : copied
    }

    private static func synthesizeCommandC() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyC: CGKeyCode = 0x08  // 'c'
        let down = CGEvent(keyboardEventSource: source, virtualKey: keyC, keyDown: true)
        down?.flags = .maskCommand
        let up = CGEvent(keyboardEventSource: source, virtualKey: keyC, keyDown: false)
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    // MARK: - Pasteboard save/restore

    private static func snapshot(_ pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        (pasteboard.pasteboardItems ?? []).map { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        }
    }

    private static func restore(_ pasteboard: NSPasteboard, items: [NSPasteboardItem]) {
        pasteboard.clearContents()
        if !items.isEmpty {
            pasteboard.writeObjects(items)
        }
    }
}
