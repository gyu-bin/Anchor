//
//  AppGuideView.swift
//  Anchor
//

import SwiftUI

struct AppGuideView: View {
    @Environment(\.colorScheme) private var scheme

    var isReplay: Bool = false
    var onFinish: () -> Void

    @State private var page = 0

    private let pageCount = 4

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcomePage.tag(0)
                howItWorksPage.tag(1)
                screenTimePage.tag(2)
                startPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            bottomBar
        }
        .anchorScreenBackground()
    }

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "key.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.anchorAccent(scheme))
                .symbolRenderingMode(.hierarchical)
            Text(AppBrand.displayName)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color.anchorText(scheme))
            Text(AppCopy.Guide.welcomeBody)
                .font(.body)
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.anchorSub(scheme))
                .padding(.horizontal, 28)
            Spacer()
        }
    }

    private var howItWorksPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Text(AppCopy.Guide.howTitle)
                .font(.title2.bold())
                .foregroundStyle(Color.anchorText(scheme))
            ForEach(AppCopy.Guide.steps, id: \.self) { step in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.anchorAccent(scheme))
                    Text(step)
                        .font(.body)
                        .foregroundStyle(Color.anchorText(scheme))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private var screenTimePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(Color.anchorAccent(scheme))
            Text(AppCopy.Guide.screenTimeTitle)
                .font(.title2.bold())
                .foregroundStyle(Color.anchorText(scheme))
            Text(AppCopy.Guide.screenTimeBody)
                .font(.body)
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.anchorSub(scheme))
                .padding(.horizontal, 28)
            Button(AppCopy.Onboarding.screenTimeAllow) {
                Task {
                    try? await ShieldManager.requestAuthorization()
                }
            }
            .buttonStyle(AnchorSecondaryButtonStyle())
            .padding(.horizontal, 28)
            Spacer()
        }
    }

    private var startPage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(Color.anchorAccent(scheme))
            Text(AppCopy.Guide.startTitle)
                .font(.title2.bold())
                .foregroundStyle(Color.anchorText(scheme))
            Text(AppCopy.Guide.startBody)
                .font(.body)
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.anchorSub(scheme))
                .padding(.horizontal, 28)
            Spacer()
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if page > 0 {
                Button(AppCopy.Common.back) {
                    withAnimation { page -= 1 }
                }
                .buttonStyle(AnchorSecondaryButtonStyle())
            }

            Button(primaryButtonTitle) {
                if page < pageCount - 1 {
                    withAnimation { page += 1 }
                } else {
                    finish()
                }
            }
            .buttonStyle(AnchorButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var primaryButtonTitle: String {
        if page < pageCount - 1 { return AppCopy.Common.next }
        return isReplay ? AppCopy.Guide.replayDone : AppCopy.Guide.start
    }

    private func finish() {
        if !isReplay {
            UserDefaults.standard.set(true, forKey: AppGuideStorage.hasSeenGuideKey)
        }
        onFinish()
    }
}
