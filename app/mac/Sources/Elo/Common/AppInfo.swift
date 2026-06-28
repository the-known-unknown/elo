import Foundation

/// App-wide constants, kept in one place so the name lives in a single source.
///
/// Values are read from the bundle's `Info.plist` when available (so they stay in
/// sync with what macOS displays) and fall back to compile-time constants. The
/// fallback matters in dev: running the bare binary via `swift run` has no
/// embedded Info.plist, so `Bundle.main` lookups return `nil` there.
enum AppInfo {
    /// Human-facing app name, e.g. "Elo". Used in the menu bar, logs, etc.
    static let name: String =
        infoString("CFBundleDisplayName")
        ?? infoString("CFBundleName")
        ?? "Elo"

    /// Bundle identifier, e.g. "com.tku.elo".
    static let bundleIdentifier: String =
        Bundle.main.bundleIdentifier ?? "com.tku.elo"

    /// Marketing version, e.g. "0.1.0" (CFBundleShortVersionString).
    static let version: String =
        infoString("CFBundleShortVersionString") ?? "0.0.0"

    /// Build number, e.g. "1" (CFBundleVersion).
    static let build: String =
        infoString("CFBundleVersion") ?? "0"

    /// Copyright notice (NSHumanReadableCopyright).
    static let copyright: String =
        infoString("NSHumanReadableCopyright") ?? ""

    /// Convenience prefix for log lines, e.g. "[Elo]".
    static let logPrefix: String = "[\(name)]"

    /// Returns a non-empty Info.plist string for `key`, or `nil`.
    private static func infoString(_ key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
            !value.isEmpty
        else { return nil }
        return value
    }
}
