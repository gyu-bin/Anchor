//
//  RoutineItemRow.swift
//  Anchor
//

import SwiftUI

struct RoutineItemRow: View {
    @Environment(\.colorScheme) private var scheme

    let item: RoutineItem
    let isCompleted: Bool
    var isCurrent: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(iconBackground)
                        .frame(width: 40, height: 40)
                    Image(systemName: item.icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(iconForeground)
                }

                Text(item.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isCompleted ? Color.anchorSub(scheme) : Color.anchorText(scheme))
                    .strikethrough(isCompleted, color: Color.anchorSub(scheme).opacity(0.6))

                Spacer()

                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        isCompleted ? Color.anchorAccent(scheme) : Color.anchorSub(scheme).opacity(0.3)
                    )
            }
            .padding(.horizontal, AnchorLayout.cardPadding)
            .padding(.vertical, 14)
            .background(rowBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var iconBackground: Color {
        if isCompleted {
            return Color.anchorAccent(scheme).opacity(0.14)
        }
        if isCurrent {
            return Color.anchorHighlight(scheme)
        }
        return Color.anchorSubBg(scheme)
    }

    private var iconForeground: Color {
        if isCompleted || isCurrent {
            return Color.anchorAccent(scheme)
        }
        return Color.anchorSub(scheme)
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isCurrent {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.anchorHighlight(scheme))
                .padding(.horizontal, 8)
        } else {
            Color.clear
        }
    }
}
