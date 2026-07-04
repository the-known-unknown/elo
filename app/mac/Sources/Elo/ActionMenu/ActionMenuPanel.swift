import AppKit
import SwiftUI

/// A borderless, non-activating floating panel that hosts the action overlay.
///
/// `.nonactivatingPanel` lets the overlay receive clicks without activating Elo
/// or stealing focus from the app you're writing in. The panel is transparent;
/// the cards provide their own background and shadow.
final class ActionMenuPanel: NSPanel {
    init<Content: View>(content: Content) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 240),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .statusBar
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let hosting = NSHostingView(rootView: content)
        hosting.layoutSubtreeIfNeeded()
        contentView = hosting
        setContentSize(hosting.fittingSize)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
