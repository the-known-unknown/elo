import AppKit

/// Owns the menu-bar status item for the background agent (there is no Dock icon
/// or main window). `NSStatusItem` can't be subclassed — instances come from
/// `NSStatusBar`'s factory — so we hold one and configure it here.
///
/// The menu is data-driven: edit `menuItems` to add, remove, or reorder rows.
/// Action handlers are required at construction time.
final class StatusItemController {
    private let onSettings: () -> Void
    private let onAbout: () -> Void
    private let onQuit: () -> Void

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    init(
        onSettings: @escaping () -> Void,
        onAbout: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onSettings = onSettings
        self.onAbout = onAbout
        self.onQuit = onQuit

        statusItem.button?.image = Self.menuBarIcon
        rebuildMenu()
    }

    /// The status-bar glyph. Prefers the bundled custom icon (`MenuBarIcon.png` /
    /// `MenuBarIcon@2x.png`, copied into the app bundle by `build_app.sh`), falling
    /// back to an SF Symbol when running via `swift run` (no bundle, so
    /// `Bundle.main` can't resolve the custom asset). Always a template image so
    /// AppKit tints it correctly for light/dark and the selection highlight.
    private static var menuBarIcon: NSImage? {
        let image = Bundle.main.image(forResource: "MenuBarIcon")
            ?? NSImage(systemSymbolName: "pencil.and.scribble", accessibilityDescription: AppInfo.name)
        image?.isTemplate = true
        return image
    }

    /// Declarative menu definition. Order here is the order shown.
    private var menuItems: [MenuItem] {
        [
            MenuItem(title: "Settings…", handler: onSettings),
            MenuItem(title: "About \(AppInfo.name)", handler: onAbout),
            .separator,
            MenuItem(title: "Quit \(AppInfo.name)", keyEquivalent: "q", handler: onQuit),
        ]
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menuItems.forEach { menu.addItem($0.makeNSMenuItem()) }
        statusItem.menu = menu
    }
}
