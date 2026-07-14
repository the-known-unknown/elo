import Foundation

/// Builds the LLM prompt for a rewrite from the selected text and the chosen action.
enum PromptBuilder {
    static func rewritePrompt(input: String, action: Function) -> String {
        """
        You are an AI writing assistant that helps users with editing text.

        <user_input>
        \(input)
        </user_input>

        Here is the instruction provided by the user. Apply these instructions to the user input shown above, and generate text output:
        <instructions>
        title: \(action.label)
        ---
        \(action.prompt)
        </instructions>
        """
    }
}
