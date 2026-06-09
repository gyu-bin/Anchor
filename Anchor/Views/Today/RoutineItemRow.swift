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
    /// true면 미완료 항목을 체크할 수 없음 (마감이 지난 루틴).
    var isDeadlineLocked: Bool = false
    let onTap: () -> Void

    private var isUncheckLocked: Bool {
        isCompleted && !allowsUncheck
    }

    private var isTapBlocked: Bool {
        isUncheckLocked || (!isCompleted && isDeadlineLocked)
    }

    var body: some View {
        Button {
            guard !isTapBlocked else { return }
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
                    .foregroundStyle(
                        isCompleted
                            ? Color.anchorSub(scheme)
                            : (isDeadlineLocked ? Color.anchorSub(scheme).opacity(0.5) : Color.anchorText(scheme))
                    )
                    .strikethrough(isCompleted, color: Color.anchorSub(scheme).opacity(0.6))

                Spacer()

                statusIcon
            }
            .padding(.horizontal, AnchorLayout.cardPadding)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(RoutineRowButtonStyle())
        .opacity(!isCompleted && isDeadlineLocked ? 0.55 : 1)
        .accessibilityLabel(item.name)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(isCompleted ? [.isSelected] : [])
    }

    @ViewBuilder
    private var statusIcon: some View {
        if !isCompleted && isDeadlineLocked {
            Image(systemName: "lock.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.anchorSub(scheme).opacity(0.35))
        } else {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundStyle(
                    isCompleted ? Color.anchorAccent(scheme) : Color.anchorSub(scheme).opacity(0.3)
                )
        }
    }

    private var accessibilityHintText: String {
        if isUncheckLocked { return "완료됨. 마감이 지나 취소할 수 없어요" }
        if !isCompleted && isDeadlineLocked { return "마감 시간이 지나 체크할 수 없어요" }
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
}

struct RoutineRowButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? (scheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03))
                    : Color.clear
            )
            .scaleEffect(configuration.isPressed ? 0.995 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, isPressed in
                isPressed
            }
    }
}
