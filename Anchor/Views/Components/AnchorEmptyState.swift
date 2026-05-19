//
//  AnchorEmptyState.swift
//  Anchor
//

import SwiftUI

/// 탭 공통 빈 화면 — 아이콘·제목·설명·선택적 CTA
struct AnchorEmptyState: View {
    @Environment(\.colorScheme) private var scheme
    @ScaledMetric(relativeTo: .title2) private var iconSize: CGFloat = 36

    var icon: String = "tray"
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(Color.anchorAccent(scheme).opacity(0.1))
                    .frame(width: 88, height: 88)
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundStyle(Color.anchorAccent(scheme))
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.anchorText(scheme))
                Text(message)
                    .font(.subheadline)
                    .lineSpacing(3)
                    .foregroundStyle(Color.anchorSub(scheme))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(AnchorButtonStyle())
                    .padding(.horizontal, 36)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .accessibilityElement(children: .combine)
    }
}
