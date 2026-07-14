import Combine
import SwiftUI

/// Reveals `text` a few characters at a time for a typewriter effect. Restarts if
/// `text` changes. Apply font/color modifiers as usual — they flow to the text.
struct TypewriterText: View {
    let text: String
    var charactersPerTick: Int = 2

    @State private var count = 0
    private let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(String(text.prefix(count)))
            .onReceive(timer) { _ in
                guard count < text.count else { return }
                count = min(count + charactersPerTick, text.count)
            }
            .onChange(of: text) { _ in
                count = 0
            }
    }
}
