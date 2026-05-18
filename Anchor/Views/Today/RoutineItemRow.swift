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
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            isCompleted
                                ? Color("AnchorAccent").opacity(0.15)
                                : Color("AnchorSubBg")
                        )
                        .frame(width: 36, height: 36)
                    Image(systemName: item.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(
                            isCompleted ? Color("AnchorAccent") : Color.anchorSub(scheme)
                        )
                }

                Text(item.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isCompleted ? Color.anchorSub(scheme) : Color.anchorText(scheme))
                    .strikethrough(isCompleted, color: Color.anchorSub(scheme))

                Spacer()

                checkmarkIcon
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .leading) {
            if isCurrent {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.anchorInfo.opacity(0.85), lineWidth: 2)
            }
        }
    }

    @ViewBuilder
    private var checkmarkIcon: some View {
        let image = Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 22))
            .foregroundStyle(isCompleted ? Color("AnchorAccent") : Color.anchorSub(scheme).opacity(0.45))

        if #available(iOS 17.0, *) {
            image.animation(.spring(response: 0.3), value: isCompleted)
        } else {
            image
        }
    }
}
