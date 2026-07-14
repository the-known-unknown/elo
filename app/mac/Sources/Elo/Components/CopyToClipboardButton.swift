import AppKit
import SwiftUI

/// A small circular button that copies `text` to the clipboard, briefly showing
/// a green checkmark as confirmation.
struct CopyToClipboardButton: View {
    let text: String

    @State private var didCopy = false

    var body: some View {
        Button(action: copy) {
            Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(didCopy ? Color.green : Color.secondary)
                .frame(width: 26, height: 26)
                .background(Circle().fill(.regularMaterial))
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.08)))
        }
        .buttonStyle(.plain)
        .help("Copy to clipboard")
    }

    private func copy() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        didCopy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { didCopy = false }
    }
}
