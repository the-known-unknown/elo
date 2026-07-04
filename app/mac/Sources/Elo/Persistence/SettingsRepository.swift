import Foundation

/// Loads and saves the settings document. Abstracted so the store can depend on
/// an interface (and tests can inject an in-memory implementation).
protocol SettingsRepository {
    func load() -> AppSettings
    func save(_ settings: AppSettings)

    /// Location of the settings file, if available (for "Reveal in Finder" etc.).
    var fileURL: URL? { get }
}

/// Persists settings as a human-readable, shareable JSON file at
/// `~/Library/Application Support/<App>/elo.settings.json`.
///
/// Reads are synchronous (used once on launch); writes are performed atomically
/// on a background queue so the UI is never blocked.
final class FileSettingsRepository: SettingsRepository {
    let fileURL: URL?

    private let ioQueue = DispatchQueue(
        label: "\(AppInfo.bundleIdentifier).settings-io", qos: .utility)

    init(fileName: String = "elo.settings.json") {
        let fileManager = FileManager.default
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let directory = base?.appendingPathComponent(AppInfo.name, isDirectory: true)
        if let directory {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        fileURL = directory?.appendingPathComponent(fileName)
    }

    func load() -> AppSettings {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else {
            // Missing file (first launch) → defaults.
            return .default
        }
        do {
            return try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            // Unreadable / schema drift → defaults, rather than crashing.
            log(
                "SettingsRepository: decode failed, using defaults (\(error.localizedDescription))."
            )
            return .default
        }
    }

    func save(_ settings: AppSettings) {
        guard let fileURL else { return }
        ioQueue.async {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(settings)
                try data.write(to: fileURL, options: [.atomic])
            } catch {
                log("SettingsRepository: save failed (\(error.localizedDescription)).")
            }
        }
    }
}
