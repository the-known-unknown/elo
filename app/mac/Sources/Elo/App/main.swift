import AppKit

// Elo runs as a background "agent" app: no Dock icon, only a menu-bar item
// and an on-demand overlay. `.accessory` is the runtime equivalent of the
// LSUIElement Info.plist flag (we set both for robustness).
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
