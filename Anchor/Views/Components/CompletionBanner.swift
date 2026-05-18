//
//  CompletionBanner.swift
//  Anchor
//

import SwiftUI

struct CompletionBanner: View {
    @Environment(\.colorScheme) private var scheme

    let totalItems: Int

    var body: some View {
        VStack(spacing: 12) {
            completionIcon

            Text("오늘 루틴 완료!")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.anchorText(scheme))

            Text("모든 앱 잠금이 해제됐어요")
                .font(.subheadline)
                .foregroundStyle(Color.anchorSub(scheme))

            if totalItems > 0 {
                Text("완료한 항목 \(totalItems)개")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.anchorSubBg(scheme))
                    .clipShape(Capsule())
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color("AnchorCard"))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 16, y: 4)
    }

    @ViewBuilder
    private var completionIcon: some View {
        if #available(iOS 17.0, *) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color("AnchorAccent"))
                .symbolEffect(.bounce, value: totalItems)
        } else {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color("AnchorAccent"))
        }
    }
}
