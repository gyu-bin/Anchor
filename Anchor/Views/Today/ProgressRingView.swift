//
//  ProgressRingView.swift
//  Anchor
//

import SwiftUI

struct ProgressRingView: View {
    @Environment(\.colorScheme) private var scheme

    var progress: Double
    var lineWidth: CGFloat = 14

    private var clamped: CGFloat {
        CGFloat(min(max(progress, 0), 1))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.anchorSubBg(scheme), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    Color.anchorAccent(scheme),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: clamped)
        }
    }
}

#Preview {
    ProgressRingView(progress: 0.62)
        .frame(width: 120, height: 120)
        .padding()
}
