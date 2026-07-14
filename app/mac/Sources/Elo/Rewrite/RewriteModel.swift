import Combine

/// State for the rewrite panel: which phase it's in and the text to display,
/// plus the action callbacks the controller wires up.
final class RewriteModel: ObservableObject {
    enum Phase {
        case loading  // waiting on the rewrite; shows the original input
        case done  // shows the rewritten result
    }

    @Published var phase: Phase = .loading
    @Published var displayedText: String

    var onUseThis: (() -> Void)?
    var onRewrite: (() -> Void)?
    var onCancel: (() -> Void)?

    init(inputText: String) {
        self.displayedText = inputText
    }
}
