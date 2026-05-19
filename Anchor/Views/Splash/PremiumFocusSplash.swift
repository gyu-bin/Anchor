//
//  PremiumFocusSplash.swift
//  Anchor
//

import SwiftUI

/// 스플래시·런치 스크린 — 항상 밝은 베이지 (다크 모드와 무관)
enum SplashAppearance {
    static let background = Color(hex: "FAF8F5")
    /// 자물쇠 뒤 은은한 대비용 (배경보다 한 톤 진함)
    static let lockPlate = Color(hex: "E6E0D4")
    static let lockShadow = Color(hex: "9A8E7E")
    static let title = Color(hex: "1C1C1E")
}

/// 스플래시와 동일한 정적 화면 (런치 스크린·DB 로딩 대기용)
struct SplashStaticView: View {
    private let lockSize: CGFloat = 140

    var body: some View {
        ZStack {
            SplashAppearance.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                SplashLockMark(size: lockSize)

                Text(AppBrand.displayName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(SplashAppearance.title)
            }
        }
        .preferredColorScheme(.light)
    }
}

/// 배경과 자물쇠 구분 — 살짝 진한 원형 면 + 부드러운 그림자
private struct SplashLockMark: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            SplashAppearance.lockPlate.opacity(0.65),
                            SplashAppearance.lockPlate.opacity(0.2),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: size * 0.05,
                        endRadius: size * 0.58
                    )
                )
                .frame(width: size * 1.12, height: size * 1.12)

            Image("SplashIcon")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .shadow(color: SplashAppearance.lockShadow.opacity(0.2), radius: 10, x: 0, y: 6)
                .shadow(color: SplashAppearance.lockShadow.opacity(0.1), radius: 3, x: 0, y: 2)
        }
    }
}

#Preview {
    SplashStaticView()
}
