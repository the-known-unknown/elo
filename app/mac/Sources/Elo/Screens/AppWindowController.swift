import AppKit
import SwiftUI

/// Base class for the app's auxiliary windows (About, Settings, …).
///
/// Elo is a background agent with no standard windows, so each window is:
///   - built lazily and reused (re-showing just re-focuses it),
///   - sized to its SwiftUI content,
///   - centered on the active screen, and
///   - brought to the front (activating the app) on `show()`.
///
/// Subclasses provide only the `title` and the SwiftUI `makeContentView()`.
/// This is an abstract base — instantiate a concrete subclass, not this directly.
class AppWindowController {
    private var window: NSWindow?

    /// The window's title bar text. Subclasses must override.
    var title: String {
        fatalError("\(type(of: self)) must override `title`.")
    }

    /// The SwiftUI content for the window. Subclasses must override.
    func makeContentView() -> AnyView {
        fatalError("\(type(of: self)) must override `makeContentView()`.")
    }

    /// Lazily builds (if needed), centers, and shows the window.
    func show() {
        let window = self.window ?? makeWindow()
        self.window = window

        NSApp.activate(ignoringOtherApps: true)
        centerOnScreen(window)
        window.makeKeyAndOrderFront(nil)
    }

    // MARK: - Construction

    private func makeWindow() -> NSWindow {
        let hostingController = NSHostingController(rootView: makeContentView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = title
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false  // we keep our own reference and reuse it

        // Force the SwiftUI content to lay out and size the window to it now, so
        // centering has the real size (otherwise the frame is still ~1x28 on
        // first open and we'd center an empty window).
        hostingController.view.layoutSubtreeIfNeeded()
        window.setContentSize(hostingController.view.fittingSize)

        return window
    }

    // MARK: - Centering

    /// Centers the window on the active screen's visible area (true center, unlike
    /// `NSWindow.center()`, which sits slightly above center).
    private func centerOnScreen(_ window: NSWindow) {
        guard let screen = NSScreen.main else {
            window.center()
            return
        }
        let visibleFrame = screen.visibleFrame
        let size = window.frame.size
        let origin = NSPoint(
            x: visibleFrame.midX - size.width / 2,
            y: visibleFrame.midY - size.height / 2
        )
        window.setFrameOrigin(origin)
    }
}
