import Combine
import Foundation

/// The single source of truth for persisted settings.
///
/// UI binds two-way to `settings` (fragment by fragment); changes auto-save to
/// disk via the repository, debounced so typing doesn't hammer the file. Services
/// subscribe to the granular publishers below so they react only to their slice.
final class SettingsStore: ObservableObject {
    @Published var settings: AppSettings

    private let repository: SettingsRepository
    private var saveCancellable: AnyCancellable?

    init(repository: SettingsRepository = FileSettingsRepository()) {
        self.repository = repository
        self.settings = repository.load()

        // Materialize the file on first launch so it exists immediately (and is
        // shareable/editable), rather than only appearing after the first change.
        if let url = repository.fileURL, !FileManager.default.fileExists(atPath: url.path) {
            repository.save(settings)
        }

        // Auto-save on change, debounced. `dropFirst()` skips the value we just
        // loaded, so opening the app doesn't immediately rewrite the file.
        saveCancellable =
            $settings
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [repository] settings in repository.save(settings) }
    }

    /// Where the settings file lives (for "Reveal in Finder" etc.).
    var settingsFileURL: URL? { repository.fileURL }

    // MARK: - Granular publishers (subscribe to just the slice you care about)

    var hotkeyPublisher: AnyPublisher<Hotkey, Never> {
        $settings.map(\.application.hotkey).removeDuplicates().eraseToAnyPublisher()
    }

    var functionsPublisher: AnyPublisher<[Function], Never> {
        $settings.map(\.application.functions).removeDuplicates().eraseToAnyPublisher()
    }
}
