//
//  RoutineEditSection.swift
//  Anchor
//

import SwiftUI

/// 루틴 카드 펼침 화면의 섹션 그룹
struct RoutineEditSection<Content: View>: View {
    @Environment(\.colorScheme) private var scheme

    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.anchorAccent(scheme))
                        .frame(width: 28, height: 28)
                        .background(Color.anchorHighlight(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.anchorText(scheme))
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .lineSpacing(2)
                            .foregroundStyle(Color.anchorSub(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }

            content
        }
        .padding(AnchorLayout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.anchorCard(scheme))
        .clipShape(RoundedRectangle(cornerRadius: AnchorLayout.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AnchorLayout.cardRadius, style: .continuous)
                .strokeBorder(Color.anchorBorder(scheme).opacity(0.55), lineWidth: 1)
        )
    }
}

/// 일정·토글 등 한 줄 행
struct RoutineFormInsetGroup<Content: View>: View {
    @Environment(\.colorScheme) private var scheme

    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.anchorSubBg(scheme))
        .clipShape(RoundedRectangle(cornerRadius: AnchorLayout.rowRadius, style: .continuous))
    }
}

struct RoutineFormDivider: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Divider()
            .overlay(Color.anchorBorder(scheme).opacity(0.45))
            .padding(.leading, 14)
    }
}
