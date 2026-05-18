//
//  PremiumFocusSplash.swift
//  Anchor
//

import SwiftUI

struct PremiumFocusSplash: View {
    static let displayDuration: TimeInterval = 1.6

    var onComplete: () -> Void

    var body: some View {
        SplashStaticView()
            .task {
                try? await Task.sleep(for: .seconds(Self.displayDuration))
                onComplete()
            }
    }
}

/// 스플래시와 동일한 정적 화면 (런치 스크린·DB 로딩 대기용)
struct SplashStaticView: View {
    private let iconSize: CGFloat = 140

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Image("SplashIcon")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(
                        RoundedRectangle(cornerRadius: iconSize * 0.214, style: .continuous)
                    )

                Text(AppBrand.displayName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: "E8ECF2"))
            }
        }
    }
}

#Preview {
    PremiumFocusSplash(onComplete: {})
}
