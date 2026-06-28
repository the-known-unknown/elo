import Foundation

/// App-wide logging helper. Prefixes every message with the app name (e.g.
/// "[Elo]") so log lines are easy to filter:
///
///     log("Launched")   // -> [Elo] Launched
///
/// Use this instead of calling `NSLog` directly. The message is passed as an
/// argument (not as the format string) so a literal `%` in the text is safe.
func log(_ message: String) {
    NSLog("%@", "\(AppInfo.logPrefix) \(message)")
}
