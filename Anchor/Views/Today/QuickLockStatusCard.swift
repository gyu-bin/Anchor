//
//  QuickLockStatusCard.swift
//  Anchor
//

import SwiftUI

/// 오늘 탭 — 즉시 잠금이 켜져 있을 때 남은 시간과 잠긴 앱을 표시합니다.
struct QuickLockStatusCard: View {
    @Environment(\.colorScheme) private var scheme

    let remainingSeconds: Int
    let blockSummary: BlockedShieldSummary
    var onManage: (() -> Void)? = nil

    var body: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.anchorAccent(scheme))
                        .frame(width: 36, height: 36)
                        .background(Color.anchorAccent(scheme).opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(AppCopy.Today.quickLockActive)
                            .font(AnchorTypography.cardTitle(scheme))
                            .foregroundStyle(Color.anchorText(scheme))
                        Text(AppCopy.Today.quickLockCountdown(seconds: remainingSeconds))
                            .font(.subheadline.weight(.medium).monospacedDigit())
                            .foregroundStyle(Color.anchorWarning(scheme))
                            .monospacedDigit()
                    }

                    Spacer(minLength: 0)

                    if onManage != nil {
                        Button(AppCopy.Today.quickLockManage) {
                            onManage?()
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.anchorAccent(scheme))
                    }
                }

                if blockSummary.hasAnyBlock {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(AppCopy.Today.lockingAppsLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.anchorWarning(scheme))
                        BlockedShieldDisplay(
                            summary: blockSummary,
                            maxApps: 8,
                            maxWebs: 4,
                            iconSize: 28
                        )
                    }
                }
            }
            .padding(AnchorLayout.cardPadding)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AnchorLayout.cardRadius, style: .continuous)
                .stroke(Color.anchorAccent(scheme).opacity(0.35), lineWidth: 1.5)
        )
    }
}
