//
//  BlockedShieldDisplay.swift
//  Anchor
//

import SwiftUI

/// 오늘 탭 · 루틴 카드용 차단 앱/웹 표시.
struct BlockedShieldDisplay: View {
    @Environment(\.colorScheme) private var scheme

    let summary: BlockedShieldSummary
    var maxApps: Int = 8
    var maxWebs: Int = 8
    var iconSize: CGFloat = 28

    var body: some View {
        if summary.hasAnyBlock {
            VStack(alignment: .leading, spacing: 8) {
                if !summary.appTokens.isEmpty {
                    BlockedAppIconsRow(tokens: summary.appTokens, maxVisible: maxApps, iconSize: iconSize)
                }
                if !summary.webTokens.isEmpty {
                    BlockedWebIconsRow(tokens: summary.webTokens, maxVisible: maxWebs, iconSize: iconSize)
                }
                if !summary.webDomains.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(summary.webDomains, id: \.self) { domain in
                                BlockedDomainIconBadge(domain: domain)
                            }
                        }
                    }
                }
            }
        }
    }
}
