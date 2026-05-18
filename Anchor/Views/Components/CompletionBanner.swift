//
//  CompletionBanner.swift
//  Anchor
//

import SwiftUI

struct CompletionBanner: View {
    @Environment(\.colorScheme) private var scheme

    let totalItems: Int

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.anchorSuccess(scheme))
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 6) {
                Text(AppCopy.Today.completeTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.anchorText(scheme))

                Text(AppCopy.Today.completeBody)
                    .font(.subheadline)
                    .foregroundStyle(Color.anchorSub(scheme))
                    .multilineTextAlignment(.center)
            }

            if totalItems > 0 {
                Text("\(AppCopy.Today.completeCount) \(totalItems)개")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.anchorSub(scheme))
            }
        }
        .frame(maxWidth: .infinity)
    }
}
