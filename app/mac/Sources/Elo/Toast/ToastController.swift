import AppKit

/// Shows a transient toast near the bottom-center of the screen: plays a warning
/// sound, slides/expands the toast in, holds for `duration`, then reverses out.
final class ToastController {
    private let panelSize = NSSize(width: 460, height: 150)

    private var panel: ToastPanel?
    private var model: ToastModel?
    private var hideWorkItem: DispatchWorkItem?
    private var removeWorkItem: DispatchWorkItem?

    func show(
        message: String,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil,
        duration: TimeInterval = 3
    ) {
        dismiss()
        playWarningSound()

        let model = ToastModel()
        let view = ToastView(
            model: model,
            message: message,
            actionTitle: actionTitle,
            onAction: onAction == nil
                ? nil
                : { [weak self] in
                    onAction?()
                    self?.hide()
                },
            onClose: { [weak self] in self?.hide() }
        )
        // Always interactive now — the close button needs to receive clicks.
        let panel = ToastPanel(content: view, size: panelSize, interactive: true)
        position(panel)
        panel.orderFrontRegardless()
        self.model = model
        self.panel = panel

        // Trigger the slide-up/expand on the next runloop tick so the initial
        // (hidden) state renders first and the change animates.
        DispatchQueue.main.async { model.isPresented = true }

        // Auto-dismiss after `duration`.
        let hideItem = DispatchWorkItem { [weak self] in self?.hide() }
        hideWorkItem = hideItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: hideItem)
    }

    /// Animates the toast out, then removes the panel once it's off-screen.
    private func hide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        guard let model, removeWorkItem == nil else { return }
        model.isPresented = false
        let remove = DispatchWorkItem { [weak self] in self?.dismiss() }
        removeWorkItem = remove
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: remove)
    }

    func dismiss() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        removeWorkItem?.cancel()
        removeWorkItem = nil
        panel?.orderOut(nil)
        panel = nil
        model = nil
    }

    private func position(_ panel: NSPanel) {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let frame = screen?.visibleFrame else { return }
        let origin = NSPoint(x: frame.midX - panelSize.width / 2, y: frame.minY + 12)
        panel.setFrameOrigin(origin)
    }

    private func playWarningSound() {
        if let sound = NSSound(named: "Basso") {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
}
