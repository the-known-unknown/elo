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
                OptionRow(
                    label: "No functions configured", position: .only, cornerRadius: cornerRadius,
                    action: nil)
            } else {
                ForEach(Array(functions.enumerated()), id: \.element.id) { index, function in
                    if index > 0 {
                        Divider()
                    }
                    OptionRow(
                        label: function.label.isEmpty ? "Untitled" : function.label,
                        position: .at(index: index, count: functions.count),
                        cornerRadius: cornerRadius,
                        action: { onSelect(function) }
                    )
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

/// Where a row sits in the list, so its hover highlight can round the matching
/// outer corners (first: top, last: bottom, only: both, middle: none).
private enum RowPosition {
    case first, middle, last, only

    static func at(index: Int, count: Int) -> RowPosition {
        if count == 1 { return .only }
        if index == 0 { return .first }
        if index == count - 1 { return .last }
        return .middle
    }

    var roundsTop: Bool { self == .first || self == .only }
    var roundsBottom: Bool { self == .last || self == .only }
}

/// A single selectable row. On hover it takes the macOS menu look — an
/// accent-colored background with white text — with corners matching the container.
private struct OptionRow: View {
    let label: String
    let position: RowPosition
    let cornerRadius: CGFloat
    let action: (() -> Void)?
    @State private var isHovering = false

    var body: some View {
        Button(action: { action?() }) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 13)
                .background(highlightShape.fill(isHovering ? Color.accentColor : Color.clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .onHover { isHovering = action != nil && $0 }
    }

    private var textColor: Color {
        if isHovering { return .white }
        return action == nil ? .secondary : .primary
    }

    private var highlightShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: position.roundsTop ? cornerRadius : 0,
            bottomLeadingRadius: position.roundsBottom ? cornerRadius : 0,
            bottomTrailingRadius: position.roundsBottom ? cornerRadius : 0,
            topTrailingRadius: position.roundsTop ? cornerRadius : 0,
            style: .continuous
        )
    }
}
