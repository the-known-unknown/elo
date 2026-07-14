import AppKit
import SwiftUI

/// A borderless, non-activating floating panel that hosts the rewrite UI.
///
/// It deliberately never becomes key: that keeps the app you were writing in
/// frontmost, so "Use this" can paste the result straight back into it.
final class RewritePanel: NSPanel {
    init<Content: View>(content: Content) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 340),
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
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let hosting = NSHostingView(rootView: content)
        hosting.layoutSubtreeIfNeeded()
        contentView = hosting
        setContentSize(hosting.fittingSize)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
