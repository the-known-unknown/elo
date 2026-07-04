import Foundation

/// The full persisted settings document (mirrors `elo.settings.json`).
///
/// Only user-configurable data lives here. Live OS state — launch-at-login
/// (`SMAppService`) and the Accessibility permission (TCC) — is intentionally
/// excluded, since a saved copy would drift from reality.
struct AppSettings: Codable, Equatable {
    var schemaVersion: Int
    var application: ApplicationSettings

    /// Bumped when the on-disk shape changes, to drive future migrations.
    static let currentSchemaVersion = 1

    static let `default` = AppSettings(
        schemaVersion: currentSchemaVersion,
        application: .default
    )
}

/// Settings shown on the "Application" tab that are persisted.
struct ApplicationSettings: Codable, Equatable {
    var hotkey: Hotkey
    var functions: [Function]

    static let `default` = ApplicationSettings(
        hotkey: .default,
        functions: Function.defaults
    )
}
