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
    /// false면 완료 항목 탭으로 체크 해제 불가 (마감 지난 루틴 등).
    var allowsUncheck: Bool = true
    let onTap: () -> Void

    private var isUncheckLocked: Bool {
        isCompleted && !allowsUncheck
    }

    var body: some View {
        Button {
            guard !isUncheckLocked else { return }
            onTap()
        } label: {
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
        .accessibilityLabel(item.name)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(isCompleted ? [.isSelected] : [])
    }

    private var accessibilityHintText: String {
        if isUncheckLocked { return "완료됨. 마감이 지나 취소할 수 없어요" }
        if isCompleted { return "완료됨. 다시 탭하면 취소" }
        return "탭하여 완료"
    }

    private var iconBackground: Color {
        isCompleted
            ? Color.anchorAccent(scheme).opacity(0.14)
            : Color.anchorHighlight(scheme)
    }

    private var iconForeground: Color {
        isCompleted ? Color.anchorAccent(scheme) : Color.anchorAccent(scheme)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.anchorSubBg(scheme))
            .padding(.horizontal, 8)
    }
}
