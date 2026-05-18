//
//  PremiumFocusSplash.swift
//  Anchor
//

import SwiftUI

struct PremiumFocusSplash: View {
    static let displayDuration: TimeInterval = 3.0

    @Environment(\.colorScheme) private var scheme

    var onComplete: () -> Void

    @State private var ringProgress: CGFloat = 0
    @State private var unlockProgress: CGFloat = 0
    @State private var contentOpacity: CGFloat = 0

    private let ringSize: CGFloat = 200
    private let ringWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Color.anchorBg(scheme).ignoresSafeArea()
            LinearGradient(
                colors: [Color.anchorAccent(scheme).opacity(0.08), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .stroke(Color.anchorBorder(scheme), lineWidth: ringWidth)
                        .frame(width: ringSize, height: ringSize)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            Color.anchorAccent(scheme),
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: ringSize, height: ringSize)

                    PremiumLockShape(unlockProgress: unlockProgress)
                        .stroke(
                            Color.anchorAccent(scheme),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: 72, height: 88)
                }

                Text(AppBrand.displayName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.anchorText(scheme))
                    .opacity(contentOpacity)
            }
            .opacity(contentOpacity)
        }
        .onAppear { runSequence() }
    }

    private func runSequence() {
        withAnimation(.easeOut(duration: 0.35)) {
            contentOpacity = 1
        }

        withAnimation(.easeInOut(duration: 1.35)) {
            ringProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                unlockProgress = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.displayDuration) {
            onComplete()
        }
    }
}

// MARK: - Shapes

struct PremiumLockShape: Shape {
    var unlockProgress: CGFloat

    var animatableData: CGFloat {
        get { unlockProgress }
        set { unlockProgress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let body = CGRect(x: w * 0.18, y: h * 0.42, width: w * 0.64, height: h * 0.5)
        path.addRoundedRect(in: body, cornerSize: CGSize(width: w * 0.12, height: w * 0.12))

        let shackleLift = unlockProgress * h * 0.14
        let left = CGPoint(x: w * 0.32, y: h * 0.42 - shackleLift)
        let right = CGPoint(x: w * 0.68, y: h * 0.42 - shackleLift)
        let arcTop = h * 0.12 - shackleLift * 0.5
        let openSpread = unlockProgress * w * 0.1

        path.move(to: left)
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: arcTop),
            control: CGPoint(x: w * 0.28 - openSpread, y: h * 0.08)
        )
        path.addQuadCurve(
            to: right,
            control: CGPoint(x: w * 0.72 + openSpread, y: h * 0.08)
        )

        return path
    }
}

#Preview {
    PremiumFocusSplash(onComplete: {})
}
