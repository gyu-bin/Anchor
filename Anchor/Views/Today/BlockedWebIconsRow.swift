//
//  BlockedWebIconsRow.swift
//  Anchor
//

import FamilyControls
import ManagedSettings
import SwiftUI

struct BlockedWebIconsRow: View {
    @Environment(\.colorScheme) private var scheme

    let tokens: [WebDomainToken]
    var maxVisible: Int = 8
    var iconSize: CGFloat = 28

    var body: some View {
        if tokens.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(tokens.prefix(maxVisible)), id: \.self) { token in
                        Label(token)
                            .labelStyle(.iconOnly)
                            .frame(width: iconSize, height: iconSize)
                            .background(Color.anchorSubBg(scheme))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    if tokens.count > maxVisible {
                        Text("+\(tokens.count - maxVisible)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.anchorSub(scheme))
                            .frame(width: iconSize, height: iconSize)
                            .background(Color.anchorSubBg(scheme))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
    }
}
