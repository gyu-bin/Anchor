//
//  HistoryStatusLegendItem.swift
//  Anchor
//

import SwiftUI

struct HistoryStatusLegendItem: View {
    @Environment(\.colorScheme) private var scheme

    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color)
                .frame(width: 14, height: 14)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.anchorText(scheme))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
        }
    }
}
