import AppKit

/// Drives the rewrite flow: shows the glass panel, runs the (stubbed) rewrite,
/// and handles Use this / Re-write / Cancel (and Escape).
final class RewriteController {
    private var panel: RewritePanel?
    private var model: RewriteModel?
    private var escMonitor: Any?

    private var action: Function?
    private var input = ""
    /// Bumped whenever a rewrite is superseded (re-write) or cancelled (dismiss),
    /// so a stale completion is ignored.
    private var generation = 0

    /// Begins a rewrite: shows the panel over the original input and kicks off the call.
    func start(action: Function, input: String) {
        dismiss()
        self.action = action
        self.input = input

        let model = RewriteModel(inputText: input)
        model.onUseThis = { [weak self] in self?.useResult() }
        model.onRewrite = { [weak self] in self?.runRewrite() }
        model.onCancel = { [weak self] in self?.dismiss() }
        self.model = model

        let panel = RewritePanel(content: RewriteView(model: model))
        position(panel, near: NSEvent.mouseLocation)
        panel.orderFrontRegardless()
        self.panel = panel

        installEscMonitor()
        runRewrite()
    }

    // MARK: - Rewrite call

    private func runRewrite() {
        guard let model, let action else { return }
        model.phase = .loading
        model.displayedText = input

        generation += 1
        let id = generation
        let prompt = PromptBuilder.rewritePrompt(input: input, action: action)
        log("Rewrite: running \"\(action.label)\".")

        RewriteService.rewriteText(prompt: prompt) { [weak self] result in
            guard let self, id == self.generation, let model = self.model else { return }
            model.displayedText = result
            model.phase = .done
        }
    }

    // MARK: - Actions

    private func useResult() {
        guard let model, model.phase == .done else { return }
        let text = model.displayedText
        dismiss()
        TextInserter.insert(text)
    }

    func dismiss() {
        generation += 1  // invalidate any in-flight rewrite
        panel?.orderOut(nil)
        panel = nil
        model = nil
        action = nil
        input = ""
        if let escMonitor {
            NSEvent.removeMonitor(escMonitor)
            self.escMonitor = nil
        }
    }

    // MARK: - Escape

    private func installEscMonitor() {
        // The panel never becomes key, so Escape arrives as a global event.
        escMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 53 {  // Escape
                self?.dismiss()
            }
        }
    }

    // MARK: - Positioning

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
}
