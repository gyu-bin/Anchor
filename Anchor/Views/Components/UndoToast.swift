//
//  UndoToast.swift
//  Anchor
//

import SwiftUI

struct UndoToast: View {
    @Environment(\.colorScheme) private var scheme

    let onUndo: () -> Void

    var body: some View {
        HStack {
            Text(AppCopy.Today.undoMessage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.anchorText(scheme))
            Spacer()
            Button(AppCopy.Today.undoAction, action: onUndo)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.anchorAccent(scheme))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.anchorCard(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
    }
}
