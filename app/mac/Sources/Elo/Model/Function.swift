import Foundation

/// A user-defined writing action: a label plus the prompt sent to the AI.
///
/// Persisted as part of the settings document. `id` gives stable identity for
/// SwiftUI lists and (later) the overlay menu.
struct Function: Codable, Equatable, Identifiable {
    var id: UUID
    var label: String
    var prompt: String

    init(id: UUID = UUID(), label: String, prompt: String) {
        self.id = id
        self.label = label
        self.prompt = prompt
    }

    /// Maximum number of functions shown in the UI / overlay menu.
    static let maxCount = 4

    /// A fresh, empty function for a new slot.
    static func empty() -> Function {
        Function(label: "", prompt: "")
    }

    /// The three prefilled defaults from the product brief.
    static let defaults: [Function] = [
        Function(
            label: "Improve writing",
            prompt:
                "Can you improve this text, fix typos and improve the grammar to make it sound more polished?"
        ),
        Function(
            label: "Make Concise",
            prompt: "Make this text more concise, without losing important detail"
        ),
        Function(
            label: "Itemize",
            prompt:
                "I would like you to rewrite this text as a simple bulleted list, without losing important detail. Ensure each bullet is concise. Feel free to organize this into a group of categories with sub-bullets in each (if applicable)"
        ),
    ]
}
