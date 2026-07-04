import AppKit

/// Shows the action menu — the list of functions the user can run on the current
/// selection. Triggered by the global hotkey.
///
/// For now this is a native `NSMenu` popped up at the cursor; a richer overlay can
/// replace it later without changing the trigger/selection plumbing.
final class ActionMenuController {
    /// Called with the chosen function and the text that was selected when the
    /// menu was triggered.
    private let onSelect: (Function, String?) -> Void

    init(onSelect: @escaping (Function, String?) -> Void) {
        self.onSelect = onSelect
    }

    func show(functions: [Function], selectedText: String?) {
        let menu = NSMenu()

        if functions.isEmpty {
            let placeholder = NSMenuItem(
                title: "No functions configured", action: nil, keyEquivalent: "")
            placeholder.isEnabled = false
            menu.addItem(placeholder)
        } else {
            for function in functions {
                let title = function.label.isEmpty ? "Untitled" : function.label
                let item = MenuItem(title: title) { [weak self] in
                    self?.onSelect(function, selectedText)
                }
                menu.addItem(item.makeNSMenuItem())
            }
        }

        // A menu popped up by a background agent needs the app active to track
        // mouse/keyboard. The selection was already captured before this point.
        NSApp.activate(ignoringOtherApps: true)
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
}
