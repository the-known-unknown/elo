import SwiftUI

/// The custom action overlay: a single rounded container listing the functions,
/// separated by hairline dividers.
///
/// The container uses `.regularMaterial` for a frosted, glass-like feel. (True
/// "Liquid Glass" — `.glassEffect()` — needs the macOS 26 SDK, which isn't
/// available here; the layout/corners are kept so it can be swapped in later.)
struct ActionMenuView: View {
    let functions: [Function]
    let onSelect: (Function) -> Void

    private let cornerRadius: CGFloat = 16
    @State private var isVisible = false

    var body: some View {
        optionsContainer
            .padding(8)
            .fixedSize()
            .scaleEffect(isVisible ? 1 : 0.95, anchor: .top)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                    isVisible = true
                }
            }
    }

    private var optionsContainer: some View {
        VStack(spacing: 0) {
            if functions.isEmpty {
                OptionRow(label: "No functions configured", action: nil)
            } else {
                ForEach(Array(functions.enumerated()), id: \.element.id) { index, function in
                    if index > 0 {
                        Divider()
                    }
                    OptionRow(label: function.label.isEmpty ? "Untitled" : function.label) {
                        onSelect(function)
                    }
                }
            }
        }
        .background(
            .regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        )
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
    }
}

/// A single selectable row in the grouped container, sized to the widest label.
private struct OptionRow: View {
    let label: String
    let action: (() -> Void)?
    @State private var isHovering = false

    var body: some View {
        Button(action: { action?() }) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(action == nil ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 13)
                .background(isHovering ? Color.primary.opacity(0.06) : Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .onHover { isHovering = action != nil && $0 }
    }
}
