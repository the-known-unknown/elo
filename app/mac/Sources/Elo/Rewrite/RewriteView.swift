import AppKit
import SwiftUI

/// The rewrite panel: a glass container showing the text (non-editable) with a
/// bottom bar that changes between the loading and done phases.
struct RewriteView: View {
    @ObservedObject var model: RewriteModel

    private let cornerRadius: CGFloat = 16

    var body: some View {
        VStack(spacing: 14) {
            textArea
            bottomBar
        }
        .padding(16)
        .frame(width: 460, height: 240)
        .background(
            .regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        )
        .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
    }

    // Read-only text (selectable, but not editable). The rewritten result types in;
    // the original input (while loading) is shown plainly.
    @ViewBuilder
    private var textContent: some View {
        switch model.phase {
        case .loading:
            Text(model.displayedText)
        case .done:
            TypewriterText(text: model.displayedText)
        }
    }

    private var textArea: some View {
        ScrollView {
            textContent
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        )
        .overlay(alignment: .bottomTrailing) {
            CopyToClipboardButton(text: model.displayedText)
                .padding(8)
        }
    }

    private var bottomBar: some View {
        HStack {
            leadingControl
            Spacer()
            trailingControls
        }
    }

    @ViewBuilder
    private var leadingControl: some View {
        switch model.phase {
        case .loading:
            Text("Rewriting…")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(nsColor: .darkGray))
        case .done:
            Button("Cancel") { model.onCancel?() }
        }
    }

    @ViewBuilder
    private var trailingControls: some View {
        switch model.phase {
        case .loading:
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.small)
        case .done:
            HStack(spacing: 10) {
                Button("Re-write") { model.onRewrite?() }
                Button("Use this") { model.onUseThis?() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
