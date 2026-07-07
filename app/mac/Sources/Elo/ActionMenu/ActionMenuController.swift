import AppKit

/// Shows the action overlay — a custom floating panel listing the functions the
/// user can run on the current selection. Triggered by the global hotkey.
///
/// Supports keyboard navigation: Up/Down move the highlight (no wrap), Return
/// activates it, Escape closes. Arrow/Return/Escape are consumed by a local
/// monitor so they don't leak into the app you were in.
final class ActionMenuController {
    /// Called with the chosen function and the selection captured when the menu opened.
    private let onSelect: (Function, Selection?) -> Void

    private var panel: ActionMenuPanel?
    private var outsideClickMonitor: Any?
    private var keyMonitor: Any?
    private var appSwitchObserver: NSObjectProtocol?

    // State for the currently-shown menu.
    private var model: ActionMenuModel?
    private var functions: [Function] = []
    private var selection: Selection?

    init(onSelect: @escaping (Function, Selection?) -> Void) {
        self.onSelect = onSelect
    }

    func show(functions: [Function], selection: Selection?) {
        dismiss()
        self.functions = functions
        self.selection = selection

        let model = ActionMenuModel()
        self.model = model

        let view = ActionMenuView(functions: functions, model: model) { [weak self] function in
            self?.activate(function)
        }

        let panel = ActionMenuPanel(content: view)
        position(panel, near: NSEvent.mouseLocation)
        panel.makeKeyAndOrderFront(nil)  // key so it receives arrow/Return/Escape
        self.panel = panel

        installMonitors()
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
        model = nil
        functions = []
        selection = nil

        if let outsideClickMonitor {
            NSEvent.removeMonitor(outsideClickMonitor)
            self.outsideClickMonitor = nil
        }
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        if let appSwitchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(appSwitchObserver)
            self.appSwitchObserver = nil
        }
    }

    // MARK: - Selection / activation

    private func moveSelection(_ delta: Int) {
        guard let model, !functions.isEmpty else { return }
        let count = functions.count
        if let current = model.selectedIndex {
            model.selectedIndex = min(max(current + delta, 0), count - 1)  // clamp, no wrap
        } else {
            model.selectedIndex = delta > 0 ? 0 : count - 1
        }
    }

    private func activateSelected() {
        guard let index = model?.selectedIndex, functions.indices.contains(index) else { return }
        activate(functions[index])
    }

    private func activate(_ function: Function) {
        let selection = self.selection
        onSelect(function, selection)
        dismiss()
    }

    // MARK: - Positioning

    /// Places the overlay just to the right of the cursor, vertically centered on
    /// it, clamped to the current screen's visible area.
    private func position(_ panel: NSPanel, near mouse: NSPoint) {
        let size = panel.frame.size
        var origin = NSPoint(x: mouse.x + 12, y: mouse.y - size.height / 2)

        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        if let frame = screen?.visibleFrame {
            origin.x = min(max(origin.x, frame.minX + 8), frame.maxX - size.width - 8)
            origin.y = min(max(origin.y, frame.minY + 8), frame.maxY - size.height - 8)
        }
        panel.setFrameOrigin(origin)
    }

    // MARK: - Monitors

    private func installMonitors() {
        // Dismiss on a click outside the overlay.
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.dismiss()
        }

        // Handle (and consume) navigation keys while the panel is key.
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self else { return event }
            switch event.keyCode {
            case 126:  // up
                moveSelection(-1)
                return nil
            case 125:  // down
                moveSelection(1)
                return nil
            case 36, 76:  // return / keypad enter
                activateSelected()
                return nil
            case 53:  // escape
                dismiss()
                return nil
            default:
                return event
            }
        }

        // Dismiss when the user switches to another app (ignoring our own
        // activation, which making the panel key can trigger).
        appSwitchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            let activated =
                note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            if activated?.processIdentifier == NSRunningApplication.current.processIdentifier {
                return
            }
            self?.dismiss()
        }
    }
}
