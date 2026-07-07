import AppKit
import SwiftUI

/// A borderless, non-activating, click-through panel that hosts a toast.
/// Fixed-size (a bottom strip) — the controller positions it near the bottom edge.
final class ToastPanel: NSPanel {
    /// `interactive` toasts (those with a button) must receive clicks; purely
    /// informational ones stay click-through.
    init<Content: View>(content: Content, size: NSSize, interactive: Bool = false) {
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
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
        ignoresMouseEvents = !interactive
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let hosting = NSHostingView(rootView: content)
        hosting.frame = NSRect(origin: .zero, size: size)
        hosting.autoresizingMask = [.width, .height]
        contentView = hosting
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
