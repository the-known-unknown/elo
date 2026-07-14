import Foundation

/// The text-rewriting backend.
///
/// Stub for now: it waits ~2.5s to simulate a network/LLM call, then delivers
/// placeholder text on the main queue. This is where the real LLM request will go
/// (swap the delay for an async URLSession/SDK call).
enum RewriteService {
    static func rewriteText(prompt: String, completion: @escaping (String) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            completion(
                """
                Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do \
                eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim \
                ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut \
                aliquip ex ea commodo consequat.
                """
            )
        }
    }
}
