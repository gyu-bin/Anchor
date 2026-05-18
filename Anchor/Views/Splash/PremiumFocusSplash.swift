//
//  PremiumFocusSplash.swift
//  Anchor
//

import SwiftUI

struct PremiumFocusSplash: View {
    /// 스플래시 전체 노출 시간(초). 이후 `onComplete` 호출.
    static let displayDuration: TimeInterval = 3.0

    @Environment(\.colorScheme) private var scheme

    var onComplete: () -> Void

    @State private var ringProgress: CGFloat = 0
    @State private var glowPulse = false
    @State private var unlockProgress: CGFloat = 0
    @State private var showCheck = false
    @State private var finalGlow = false
    @State private var textOpacity = 0.0

    private var isDark: Bool { scheme == .dark }

    var body: some View {
        ZStack {
            SplashAnimatedBackground()

            VStack(spacing: 40) {
                VStack(spacing: 12) {
                    Text("집중 모드 활성화")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(Color.anchorText(scheme))
                        .opacity(textOpacity)

                    Text("당신의 집중이 자유가 됩니다")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.anchorSub(scheme))
                        .opacity(textOpacity)
                }

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "#FFE2A8").opacity(isDark ? 0.35 : 0.22),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 140
                            )
                        )
                        .frame(width: 280, height: 280)
                        .blur(radius: 30)
                        .scaleEffect(glowPulse ? 1.08 : 0.92)
                        .opacity(finalGlow ? 1 : 0.4)
                        .animation(
                            .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                            value: glowPulse
                        )

                    Circle()
                        .stroke(
                            Color.anchorBorder(scheme).opacity(isDark ? 0.35 : 0.55),
                            lineWidth: 16
                        )
                        .frame(width: 220, height: 220)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#A97C50"),
                                    Color(hex: "#F6D7A7"),
                                    Color(hex: "#FFF3D0"),
                                    Color(hex: "#C6925A")
                                ]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 220, height: 220)
                        .shadow(color: Color(hex: "#FFD89B").opacity(isDark ? 0.8 : 0.45), radius: 18)

                    Circle()
                        .trim(from: max(ringProgress - 0.06, 0), to: ringProgress)
                        .stroke(
                            Color.white.opacity(isDark ? 1 : 0.85),
                            style: StrokeStyle(lineWidth: 18, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 220, height: 220)
                        .blur(radius: 4)

                    PremiumLockShape(unlockProgress: unlockProgress)
                        .stroke(
                            Color(hex: "#F5D39B"),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: 90, height: 110)
                        .scaleEffect(0.96 + unlockProgress * 0.08)
                        .shadow(
                            color: Color(hex: "#FFD89B").opacity(isDark ? 0.8 : 0.5),
                            radius: finalGlow ? 16 : 6
                        )

                    PremiumCheckShape()
                        .trim(from: 0, to: showCheck ? 1 : 0)
                        .stroke(
                            isDark ? Color.white : Color(hex: "#4A6741"),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: 70, height: 70)
                        .offset(x: 44, y: 44)
                        .shadow(color: .white.opacity(isDark ? 0.7 : 0), radius: 8)

                    SplashParticleField(active: finalGlow, isDark: isDark)
                }
            }
        }
        .drawingGroup()
        .onAppear { runSequence() }
    }

    private func runSequence() {
        glowPulse = true

        withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 1.8)) {
            ringProgress = 0.92
        }

        withAnimation(.easeOut(duration: 1.0)) {
            textOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.interpolatingSpring(stiffness: 160, damping: 15)) {
                showCheck = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.interpolatingSpring(stiffness: 120, damping: 12)) {
                unlockProgress = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            withAnimation(.easeInOut(duration: 1.2)) {
                finalGlow = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.displayDuration) {
            onComplete()
        }
    }
}

// MARK: - Background (앱 AnchorBackground / AnchorSubBg)

private struct SplashAnimatedBackground: View {
    @Environment(\.colorScheme) private var scheme
    @State private var move = false

    var body: some View {
        LinearGradient(
            colors: [
                Color.anchorBg(scheme),
                Color.anchorSubBg(scheme),
                Color.anchorCard(scheme).opacity(0.35)
            ],
            startPoint: move ? .topLeading : .bottomLeading,
            endPoint: move ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: move)
        .onAppear { move = true }
    }
}

// MARK: - Particles

private struct SplashParticleSpec {
    let angle: Double
    let radius: CGFloat
    let phase: Double
    let size: CGFloat
}

private struct SplashParticleField: View {
    let active: Bool
    let isDark: Bool

    private static let specs: [SplashParticleSpec] = makeParticleSpecs()

    private static func makeParticleSpecs() -> [SplashParticleSpec] {
        var list: [SplashParticleSpec] = []
        list.reserveCapacity(20)
        for i in 0 ..< 20 {
            list.append(
                SplashParticleSpec(
                    angle: Double(i) / 20 * .pi * 2,
                    radius: CGFloat(68 + (i * 7) % 44),
                    phase: Double(i) * 0.61,
                    size: CGFloat(2 + (i % 3))
                )
            )
        }
        return list
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            Canvas { context, size in
                guard active else { return }
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let t = timeline.date.timeIntervalSinceReferenceDate

                for spec in Self.specs {
                    let drift = sin(t * 1.4 + spec.phase) * 10
                    let x = center.x + cos(spec.angle + t * 0.12) * spec.radius + drift
                    let y = center.y + sin(spec.angle + t * 0.1) * spec.radius * 0.85
                    let rect = CGRect(
                        x: x - spec.size / 2,
                        y: y - spec.size / 2,
                        width: spec.size,
                        height: spec.size
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(
                            (isDark ? Color.white : Color(hex: "#C6925A"))
                                .opacity(0.35 + 0.45 * sin(t + spec.phase))
                        )
                    )
                }
            }
        }
        .frame(width: 280, height: 280)
        .allowsHitTesting(false)
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

struct PremiumCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.12, y: rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.width * 0.38, y: rect.height * 0.78))
        path.addLine(to: CGPoint(x: rect.width * 0.88, y: rect.height * 0.22))
        return path
    }
}

#Preview {
    PremiumFocusSplash(onComplete: {})
}
