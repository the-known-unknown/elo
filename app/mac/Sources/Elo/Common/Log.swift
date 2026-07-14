import Foundation

/// App-wide logging helper. Prefixes every message with the app name (e.g.
/// "[Elo]") and writes it to two places:
///   - the console (`NSLog` → terminal/Console.app/unified log), and
///   - a plain text file at `~/Library/Logs/Elo/elo.log` you can `tail`.
///
/// Use this instead of calling `NSLog` directly. The console message is passed as
/// an argument (not the format string) so a literal `%` in the text is safe.
func log(_ message: String) {
    let line = "\(AppInfo.logPrefix) \(message)"
    NSLog("%@", line)
    FileLog.append(line)
}

/// Appends log lines to `~/Library/Logs/Elo/elo.log` on a background queue.
private enum FileLog {
    /// Location of the on-disk log file (created lazily), e.g.
    /// `~/Library/Logs/Elo/elo.log`.
    static let fileURL: URL? = {
        let fileManager = FileManager.default
        guard let library = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first
        else { return nil }
        let directory = library.appendingPathComponent("Logs/Elo", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("elo.log")
    }()

    private static let queue = DispatchQueue(label: "\(AppInfo.bundleIdentifier).filelog")

    private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func append(_ line: String) {
        guard let fileURL else { return }
        let stamped = "\(timestampFormatter.string(from: Date())) \(line)\n"

        queue.async {
            guard let data = stamped.data(using: .utf8) else { return }
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                defer { try? handle.close() }
                handle.seekToEndOfFile()
                handle.write(data)
            } else {
                // File doesn't exist yet — create it.
                try? data.write(to: fileURL)
            }
        }
    }
}
