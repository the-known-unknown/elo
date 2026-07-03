import Combine

/// Observable source of truth for the invocation hotkey.
///
/// The Settings recorder writes to `hotkey`; the app observes it to (re)register
/// the global shortcut. Not yet persisted — that arrives with the settings model.
final class HotkeyStore: ObservableObject {
    @Published var hotkey: Hotkey = .default
}
