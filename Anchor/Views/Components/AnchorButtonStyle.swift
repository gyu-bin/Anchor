//
//  AnchorButtonStyle.swift
//  Anchor
//

import SwiftUI

struct AnchorButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 52

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: minHeight)
            .background(
                RoundedRectangle(cornerRadius: AnchorLayout.buttonRadius, style: .continuous)
                    .fill(Color.anchorAccent(scheme))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(AnchorMotion.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, isPressed in
                isPressed
            }
    }
}

struct AnchorTextButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.anchorAccent(scheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.anchorHighlight(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(AnchorMotion.spring(response: 0.22, dampingFraction: 0.78), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, isPressed in
                isPressed
            }
    }
}

struct AnchorSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 52

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(Color.anchorText(scheme))
            .frame(maxWidth: .infinity)
            .frame(minHeight: minHeight)
            .background(Color.anchorSubBg(scheme))
            .clipShape(RoundedRectangle(cornerRadius: AnchorLayout.buttonRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AnchorLayout.buttonRadius, style: .continuous)
                    .strokeBorder(Color.anchorBorder(scheme), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(AnchorMotion.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, isPressed in
                isPressed
            }
    }
}

/// 설정 등 카드형 행 — 탭 영역을 카드 전체로 유지
struct SettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.8), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, isPressed in
                isPressed
            }
    }
}
