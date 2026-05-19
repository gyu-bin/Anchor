//
//  WidgetDesign.swift
//  AnchorWidget
//

import SwiftUI
import WidgetKit

enum WidgetDesign {
    static let edgeInset: CGFloat = 10
    static let rowSpacing: CGFloat = 5
}

/// Medium 위젯의 축소판 — Small은 동일 구조·비율만 줄임
enum WidgetLayoutTier {
    case small
    case medium

    var edgeInset: CGFloat { self == .small ? 8 : 10 }
    var contentSpacing: CGFloat { self == .small ? 6 : 8 }
    var bodyBottomPadding: CGFloat { self == .small ? 4 : 6 }
    var ringSize: CGFloat { self == .small ? 46 : 58 }
    var ringLineWidth: CGFloat { self == .small ? 5 : 6 }
    var ringFontSize: CGFloat { self == .small ? 12 : 14 }
    var ringItemSpacing: CGFloat { self == .small ? 7 : 10 }
    /// Small 3 · Medium 4 — 실제 표시 개수는 남은 높이로 계산
    var itemCap: Int { self == .small ? 3 : 4 }
    var rowSpacing: CGFloat { self == .small ? 4 : 5 }

    func listRowSpacing(dense: Bool) -> CGFloat {
        dense ? 3 : rowSpacing
    }

    func ringSize(forVisibleCount count: Int) -> CGFloat {
        switch self {
        case .small:
            return count >= 3 ? 42 : 46
        case .medium:
            if count >= 4 { return 48 }
            if count >= 3 { return 52 }
            return 58
        }
    }

    func estimatedRowHeight(dense: Bool) -> CGFloat {
        switch self {
        case .small: 26
        case .medium: dense ? 24 : 30
        }
    }

    func useDenseRows(visibleCount: Int) -> Bool {
        switch self {
        case .small: visibleCount >= 2
        case .medium: visibleCount >= 3
        }
    }

    /// 본문 영역 높이에 맞춰 보여 줄 항목 수 (캡·오버플로 라벨 반영)
    func visibleItemCount(availableHeight: CGFloat, totalItems: Int) -> Int {
        let cap = itemCap
        guard totalItems > 0 else { return 0 }
        guard availableHeight > 4 else { return min(totalItems, cap) }

        let overflowLabel: CGFloat = 11
        let rowH = estimatedRowHeight(dense: true)
        let spacing: CGFloat = 3
        var rows = Int((availableHeight + spacing) / (rowH + spacing))
        if totalItems > rows, rows > 0 {
            rows = max(
                1,
                Int((availableHeight - overflowLabel + spacing) / (rowH + spacing))
            )
        }
        return max(1, min(totalItems, cap, rows))
    }
    var headerCompact: Bool { self == .small }
    var lockBadgeMini: Bool { self == .small }
    var rowCompact: Bool { self == .small }
    var completeButtonCompact: Bool { self == .small }
    var emptyFontSize: CGFloat { self == .small ? 12 : 14 }
    var doneTitleSize: CGFloat { self == .small ? 14 : 16 }
    var doneSubtitleSize: CGFloat { self == .small ? 11 : 13 }
    var overflowFontSize: CGFloat { self == .small ? 10 : 11 }
}

// MARK: - Background

struct WidgetScreenBackground: View {
    var body: some View {
        ZStack {
            Color("AnchorCard")
            LinearGradient(
                colors: [
                    Color("AnchorAccent").opacity(0.12),
                    Color("AnchorAccent").opacity(0.03),
                    Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

extension View {
    /// 배경을 위젯 모서리까지 채움 (별도 inset 카드 없음)
    func widgetFullBleedChrome() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                WidgetScreenBackground()
            }
    }
}

// MARK: - Chrome

struct WidgetHeader: View {
    let isLockActive: Bool
    var compact: Bool = false
    var lockBadgeMini: Bool = false
    var progressLabel: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: compact ? 11 : 12, weight: .semibold))
                .foregroundStyle(Color("AnchorAccent"))
            Text("오늘")
                .font(.system(size: compact ? 11 : 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color("AnchorAccent"))
            Spacer(minLength: 0)
            if let progressLabel {
                Text(progressLabel)
                    .font(.system(size: compact ? 10 : 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color("AnchorAccent").opacity(0.9))
            }
            if isLockActive {
                WidgetLockBadge(compact: compact && !lockBadgeMini, mini: lockBadgeMini)
            }
        }
    }
}

struct WidgetLockBadge: View {
    var compact: Bool = false
    /// Small — 아이콘+「잠금」 미니 캡슐
    var mini: Bool = false

    var body: some View {
        Group {
            if compact && !mini {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .bold))
            } else {
                HStack(spacing: mini ? 2 : 3) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: mini ? 8 : 9, weight: .bold))
                    Text("잠금")
                        .font(.system(size: mini ? 9 : 10, weight: .semibold))
                }
            }
        }
        .foregroundStyle(Color("AnchorAccent"))
        .padding(.horizontal, mini ? 5 : (compact ? 6 : 8))
        .padding(.vertical, mini ? 3 : (compact ? 5 : 4))
        .background(Color("AnchorAccent").opacity(0.14))
        .clipShape(Capsule())
    }
}

struct WidgetRemainingRow: View {
    @Environment(\.colorScheme) private var scheme
    let item: WidgetPendingItem
    var compact: Bool = false
    var dense: Bool = false

    private var primaryText: Color {
        scheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.88)
    }

    private var secondaryText: Color {
        scheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.42)
    }

    private var tight: Bool { compact || dense }

    var body: some View {
        HStack(spacing: tight ? 4 : 6) {
            Image(systemName: item.icon.isEmpty ? "circle" : item.icon)
                .font(.system(size: tight ? 10 : 11, weight: .semibold))
                .foregroundStyle(Color("AnchorAccent"))
                .frame(width: tight ? 15 : 18, alignment: .center)

            Text(item.itemName)
                .font(.system(size: tight ? 11 : 13, weight: .semibold))
                .foregroundStyle(primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .allowsTightening(true)
                .layoutPriority(1)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Circle()
                .strokeBorder(secondaryText.opacity(0.55), lineWidth: 1.5)
                .frame(width: tight ? 12 : 16, height: tight ? 12 : 16)
        }
        .padding(.horizontal, tight ? 5 : 8)
        .padding(.vertical, dense ? 3 : (compact ? 3 : 6))
        .background(
            RoundedRectangle(cornerRadius: tight ? 6 : 8, style: .continuous)
                .fill(scheme == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.05))
        )
    }
}

struct WidgetCompleteButton: View {
    var compact: Bool = false

    var body: some View {
        Button(intent: AnchorCompleteNextIntent()) {
            HStack(spacing: compact ? 4 : 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: compact ? 12 : 14, weight: .semibold))
                Text("완료 체크")
                    .font(.system(size: compact ? 11 : 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 8 : 11)
            .background(
                LinearGradient(
                    colors: [
                        Color("AnchorAccent"),
                        Color("AnchorAccent").opacity(0.85),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
