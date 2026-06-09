//
//  AnchorCard.swift
//  Anchor
//

import SwiftUI

struct AnchorCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme

    var cornerRadius: CGFloat = AnchorLayout.cardRadius
    var elevated: Bool = true
    @ViewBuilder let content: Content

    init(
        cornerRadius: CGFloat = AnchorLayout.cardRadius,
        elevated: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.elevated = elevated
        self.content = content()
    }

    var body: some View {
        content
            .background(Color.anchorCard(scheme))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.anchorBorder(scheme).opacity(0.3), lineWidth: 0.5)
            )
            .shadow(
                color: elevated ? Color.black.opacity(0.02) : .clear,
                radius: elevated ? 12 : 0,
                y: elevated ? 2 : 0
            )
    }
}
