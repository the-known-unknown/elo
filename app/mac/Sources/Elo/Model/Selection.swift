import Foundation

/// A captured text selection plus whether we can write a replacement back in place.
struct Selection {
    let text: String

    /// True when the focused element's selected text is settable via Accessibility
    /// — i.e. the selection lives in an editable input we can replace in place.
    /// Best-effort: `false` for read-only sources (articles, PDFs) and for apps
    /// that don't expose editability over Accessibility (some browsers/Electron).
    let isEditable: Bool
}
