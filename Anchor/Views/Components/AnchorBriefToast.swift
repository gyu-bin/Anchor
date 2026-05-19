//
//  AnchorBriefToast.swift
//  Anchor
//

import SwiftUI

struct AnchorBriefToast: View {
    @Environment(\.colorScheme) private var scheme

    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.anchorWarning(scheme))
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.anchorText(scheme))
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.anchorCard(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.anchorBorder(scheme).opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.08), radius: 12, y: 4)
    }
}
