import Combine
import SwiftUI

/// Drives the toast's presented/hidden state so the controller can animate it in
/// and out from AppKit.
final class ToastModel: ObservableObject {
    @Published var isPresented = false
}

/// A transient glass pill anchored to the bottom-center of the screen. It slides
/// up from the bottom edge while expanding in width, then reverses on dismiss.
/// Optionally shows an action button (e.g. "Grant").
struct ToastView: View {
    @ObservedObject var model: ToastModel
    let message: String
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            pill
                .offset(y: model.isPresented ? 0 : 80)
                .scaleEffect(x: model.isPresented ? 1 : 0.6, anchor: .bottom)
                .opacity(model.isPresented ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.82), value: model.isPresented)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 10)
    }

    private var pill: some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            if let actionTitle {
                Button(actionTitle) { onAction?() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }

            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .symbolRenderingMode(.palette)
                        // White X on a translucent dark circle so both the mark
                        // and the circle stay visible over the toast background.
                        .foregroundStyle(Color.white, Color.black.opacity(0.45))
                }
                .buttonStyle(.plain)
                .help("Dismiss")
            }
        }
        .fixedSize()
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08)))
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
    }
}
