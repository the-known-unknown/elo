import AppKit

/// Declarative description of a single status-bar menu row.
///
/// Build menus from an array of these (see `StatusItemController`). Use the
/// `init` for a tappable row and `.separator` for a divider.
struct MenuItem {
    let title: String
    let keyEquivalent: String
    let handler: (() -> Void)?
    let isSeparator: Bool

    /// A tappable menu row.
    init(title: String, keyEquivalent: String = "", handler: @escaping () -> Void) {
        self.title = title
        self.keyEquivalent = keyEquivalent
        self.handler = handler
        self.isSeparator = false
    }

    private init() {
        self.title = ""
        self.keyEquivalent = ""
        self.handler = nil
        self.isSeparator = true
    }

    /// A divider row.
    static let separator = MenuItem()

    /// Materializes this description into an `NSMenuItem`.
    func makeNSMenuItem() -> NSMenuItem {
        guard !isSeparator else { return .separator() }
        return ClosureMenuItem(title: title, keyEquivalent: keyEquivalent, handler: handler ?? {})
    }
}

/// An `NSMenuItem` that runs a stored closure when selected, so menu rows can be
/// defined inline without a shared target/selector.
private final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(title: String, keyEquivalent: String, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(invoke), keyEquivalent: keyEquivalent)
        self.target = self
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func invoke() { handler() }
}
