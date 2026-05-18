//
//  BlockedDomainStyle.swift
//  Anchor
//

import SwiftUI

/// 도메인 → 에셋 이미지 / SF Symbol / 표시 이름.
enum BlockedDomainStyle {
    static func hostKey(_ domain: String) -> String {
        domain
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "www.", with: "", options: .anchored)
    }

    /// `Assets.xcassets`의 이미지 세트 이름. 없으면 SF Symbol 사용.
    static func presetAssetName(for domain: String) -> String? {
        let h = hostKey(domain)
        if h.contains("instagram") { return "BlockPresetInstagram" }
        if h.contains("twitter") || h == "x.com" || h.hasSuffix(".x.com") { return "BlockPresetX" }
        if h.contains("tiktok") { return "BlockPresetTikTok" }
        if h.contains("netflix") { return "BlockPresetNetflix" }
        return nil
    }

    static func systemImage(for domain: String) -> String {
        let h = hostKey(domain)
        if h.contains("youtube") || h == "youtu.be" || h.hasSuffix(".youtube.com") {
            return "play.rectangle.fill"
        }
        return "globe"
    }

    static func tint(for domain: String, scheme: ColorScheme) -> Color {
        let h = hostKey(domain)
        if h.contains("youtube") || h == "youtu.be" {
            return Color(red: 0.95, green: 0.2, blue: 0.15)
        }
        if h.contains("instagram") {
            return Color(red: 0.85, green: 0.2, blue: 0.55)
        }
        if h.contains("twitter") || h == "x.com" || h.hasSuffix(".x.com") {
            return Color(white: 0.15)
        }
        if h.contains("tiktok") {
            return Color(red: 0.2, green: 0.9, blue: 0.85)
        }
        if h.contains("netflix") {
            return Color(red: 0.75, green: 0.05, blue: 0.08)
        }
        return Color.anchorAccent(scheme)
    }

    static func displayTitle(for domain: String) -> String {
        let h = hostKey(domain)
        if h.contains("youtube") || h == "youtu.be" { return "YouTube" }
        if h.contains("instagram") { return "Instagram" }
        if h.contains("twitter") || h == "x.com" || h.hasSuffix(".x.com") { return "X" }
        if h.contains("tiktok") { return "TikTok" }
        if h.contains("netflix") { return "Netflix" }
        return domain
    }
}

/// 프리셋은 PNG 에셋, 그 외·유튜브는 SF Symbol.
struct BlockedDomainBlockImage: View {
    @Environment(\.colorScheme) private var scheme

    let domain: String
    var box: CGFloat = 44
    var symbolScale: CGFloat = 0.55

    var body: some View {
        Group {
            if let asset = BlockedDomainStyle.presetAssetName(for: domain) {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .padding(box * 0.12)
                    .frame(width: box, height: box)
            } else {
                Image(systemName: BlockedDomainStyle.systemImage(for: domain))
                    .font(.system(size: box * symbolScale, weight: .semibold))
                    .foregroundStyle(BlockedDomainStyle.tint(for: domain, scheme: scheme))
                    .frame(width: box, height: box)
            }
        }
    }
}

/// 오늘 카드: 원형 배지.
struct BlockedDomainIconBadge: View {
    @Environment(\.colorScheme) private var scheme

    let domain: String

    var body: some View {
        BlockedDomainBlockImage(domain: domain, box: 40, symbolScale: 0.5)
            .background(Color.anchorSubBg(scheme))
            .clipShape(Circle())
            .accessibilityLabel(BlockedDomainStyle.displayTitle(for: domain))
    }
}
