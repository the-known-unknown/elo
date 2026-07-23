import Foundation

/// The full persisted settings document (mirrors `elo.settings.json`).
///
/// Only user-configurable data lives here. Live OS state — launch-at-login
/// (`SMAppService`) and the Accessibility permission (TCC) — is intentionally
/// excluded, since a saved copy would drift from reality.
///
/// Decoding is **field-by-field lenient**: each top-level section falls back to
/// its own `.default` if it's missing or fails to decode, instead of a single
/// bad/absent field discarding the *entire* document (which is what the
/// synthesized `Decodable` conformance would do). This lets us add new
/// top-level sections later without silently wiping a user's existing hotkey
/// or functions the first time they launch an updated build.
struct AppSettings: Equatable {
    var schemaVersion: Int
    var application: ApplicationSettings

    /// Bumped when the on-disk shape changes, to drive future migrations.
    static let currentSchemaVersion = 1

    static let `default` = AppSettings(
        schemaVersion: currentSchemaVersion,
        application: .default
    )
}

extension AppSettings: Codable {
    private enum CodingKeys: String, CodingKey {
        case schemaVersion, application
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion =
            (try? container.decodeIfPresent(Int.self, forKey: .schemaVersion))
            ?? Self.currentSchemaVersion
        application =
            (try? container.decodeIfPresent(ApplicationSettings.self, forKey: .application))
            ?? .default
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(application, forKey: .application)
    }
}

/// Settings shown on the "Application" tab that are persisted.
struct ApplicationSettings: Equatable {
    var hotkey: Hotkey
    var functions: [Function]

    static let `default` = ApplicationSettings(
        hotkey: .default,
        functions: Function.defaults
    )
}

extension ApplicationSettings: Codable {
    private enum CodingKeys: String, CodingKey {
        case hotkey, functions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hotkey =
            (try? container.decodeIfPresent(Hotkey.self, forKey: .hotkey)) ?? Hotkey.default
        functions =
            (try? container.decodeIfPresent([Function].self, forKey: .functions))
            ?? Function.defaults
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hotkey, forKey: .hotkey)
        try container.encode(functions, forKey: .functions)
    }
}
