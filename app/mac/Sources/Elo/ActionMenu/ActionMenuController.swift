import AppKit

/// Shows the action overlay — a custom floating panel listing the functions the
/// user can run on the current selection. Triggered by the global hotkey.
final class ActionMenuController {
    /// Called with the chosen function and the selection captured when the menu opened.
    private let onSelect: (Function, Selection?) -> Void

    private var panel: ActionMenuPanel?
    private var dismissMonitor: Any?

    init(onSelect: @escaping (Function, Selection?) -> Void) {
        self.onSelect = onSelect
    }

    func show(functions: [Function], selection: Selection?) {
        dismiss()

        let view = ActionMenuView(
            functions: functions,
            onSelect: { [weak self] function in
                self?.onSelect(function, selection)
                self?.dismiss()
            }
        )

        let panel = ActionMenuPanel(content: view)
        position(panel, near: NSEvent.mouseLocation)
        panel.orderFrontRegardless()
        self.panel = panel

        installDismissMonitor()
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
        if let dismissMonitor {
            NSEvent.removeMonitor(dismissMonitor)
            self.dismissMonitor = nil
        }
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

    // MARK: - Dismissal

    /// Dismisses on any click outside the overlay, or when Escape is pressed.
    /// (Clicks on the cards are local events handled by SwiftUI, so they don't
    /// trip this global monitor.)
    private func installDismissMonitor() {
        dismissMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .keyDown]
        ) { [weak self] event in
            switch event.type {
            case .keyDown where event.keyCode == 53:  // Escape
                self?.dismiss()
            case .leftMouseDown, .rightMouseDown:
                self?.dismiss()
            default:
                break
            }
        }
    }
}
