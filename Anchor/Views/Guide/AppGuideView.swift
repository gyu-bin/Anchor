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

    private let pageCount = 6

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                morningPage.tag(0)
                eveningPage.tag(1)
                reliefPage.tag(2)
                howItWorksPage.tag(3)
                screenTimePage.tag(4)
                startPage.tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut(duration: 0.28), value: page)

            bottomBar
        }
        .anchorScreenBackground()
        .preferredColorScheme(.light)
    }

    // MARK: - Pages

    private var morningPage: some View {
        GuideEmpathyPage(
            badge: AppCopy.Guide.morningBadge,
            badgeIcon: "sunrise.fill",
            accent: Color(hex: "E8A04A"),
            title: AppCopy.Guide.morningTitle,
            message: AppCopy.Guide.morningBody,
            appChips: [
                GuideAppChip(label: "인스타", imageName: "BlockPresetInstagram"),
                GuideAppChip(label: "유튜브", systemImage: "play.rectangle.fill", tint: Color(hex: "E53935")),
            ]
        )
    }

    private var eveningPage: some View {
        GuideEmpathyPage(
            badge: AppCopy.Guide.eveningBadge,
            badgeIcon: "moon.stars.fill",
            accent: Color(hex: "7B8CDE"),
            title: AppCopy.Guide.eveningTitle,
            message: AppCopy.Guide.eveningBody,
            appChips: [
                GuideAppChip(label: "틱톡", imageName: "BlockPresetTikTok"),
                GuideAppChip(label: "유튜브", systemImage: "play.rectangle.fill", tint: Color(hex: "E53935")),
            ]
        )
    }

    private var reliefPage: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 16)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.anchorAccent(scheme).opacity(0.22),
                                Color.anchorAccent(scheme).opacity(0.06),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "lock.iphone")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(Color.anchorAccent(scheme))
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 14) {
                Text(AppCopy.Guide.reliefTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.anchorText(scheme))

                Text(AppCopy.Guide.reliefHighlight)
                    .font(.system(size: 20, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .foregroundStyle(Color.anchorAccent(scheme))

                Text(AppCopy.Guide.reliefBody)
                    .font(.body)
                    .lineSpacing(5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.anchorSub(scheme))
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 16)
        }
    }

    private var howItWorksPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer(minLength: 12)

            Text(AppCopy.Guide.howTitle)
                .font(AnchorTypography.screenTitle(scheme))
                .foregroundStyle(Color.anchorText(scheme))
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(Array(AppCopy.Guide.steps.enumerated()), id: \.offset) { index, step in
                    GuideStepRow(
                        number: index + 1,
                        icon: step.icon,
                        text: step.text
                    )
                }
            }
            .padding(.horizontal, 20)

            Text(AppCopy.Guide.howNote)
                .font(.subheadline)
                .lineSpacing(4)
                .foregroundStyle(Color.anchorSub(scheme))
                .padding(.horizontal, 24)
                .padding(.top, 4)

            Spacer(minLength: 12)
        }
    }

    private var screenTimePage: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 16)

            GuideIconBadge(
                systemName: "lock.shield.fill",
                tint: Color.anchorAccent(scheme)
            )

            VStack(spacing: 12) {
                Text(AppCopy.Guide.screenTimeTitle)
                    .font(AnchorTypography.screenTitle(scheme))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.anchorText(scheme))

                Text(AppCopy.Guide.screenTimeBody)
                    .font(.body)
                    .lineSpacing(5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.anchorSub(scheme))
            }
            .padding(.horizontal, 28)

            Button(AppCopy.Onboarding.screenTimeAllow) {
                Task {
                    try? await ShieldManager.requestAuthorization()
                }
            }
            .buttonStyle(AnchorSecondaryButtonStyle())
            .padding(.horizontal, 28)

            Spacer(minLength: 16)
        }
    }

    private var startPage: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)

            Image("SplashIcon")
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(scheme == .dark ? 0.35 : 0.12), radius: 16, y: 8)

            VStack(spacing: 12) {
                Text(AppCopy.Guide.startTitle)
                    .font(AnchorTypography.screenTitle(scheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .foregroundStyle(Color.anchorText(scheme))

                Text(AppCopy.Guide.startBody)
                    .font(.body)
                    .lineSpacing(5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.anchorSub(scheme))
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 20)
        }
    }

    // MARK: - Chrome

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

// MARK: - Components

private struct GuideEmpathyPage: View {
    @Environment(\.colorScheme) private var scheme

    let badge: String
    let badgeIcon: String
    let accent: Color
    let title: String
    let message: String
    let appChips: [GuideAppChip]

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 12)

            HStack(spacing: 6) {
                Image(systemName: badgeIcon)
                    .font(.caption.weight(.semibold))
                Text(badge)
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(accent.opacity(0.14))
            .clipShape(Capsule())

            Text(title)
                .font(AnchorTypography.screenTitle(scheme))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .foregroundStyle(Color.anchorText(scheme))
                .padding(.horizontal, 24)

            AnchorCard {
                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        ForEach(appChips) { chip in
                            chip
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Text(message)
                        .font(.subheadline)
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.anchorSub(scheme))
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 12)
        }
    }
}

private struct GuideAppChip: View, Identifiable {
    @Environment(\.colorScheme) private var scheme

    var id: String { label }
    let label: String
    var imageName: String?
    var systemImage: String?
    var tint: Color?

    var body: some View {
        VStack(spacing: 8) {
            Group {
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(tint ?? Color.anchorText(scheme))
                }
            }
            .frame(width: 52, height: 52)
            .background(Color.anchorSubBg(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.anchorSub(scheme))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct GuideStepRow: View {
    @Environment(\.colorScheme) private var scheme

    let number: Int
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.anchorAccent(scheme).opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("\(number)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.anchorAccent(scheme))
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.anchorAccent(scheme))
                    .frame(width: 22, alignment: .center)
                    .padding(.top, 2)

                Text(text)
                    .font(.body)
                    .lineSpacing(3)
                    .foregroundStyle(Color.anchorText(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.anchorCard(scheme))
        .clipShape(RoundedRectangle(cornerRadius: AnchorLayout.rowRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AnchorLayout.rowRadius, style: .continuous)
                .strokeBorder(Color.anchorBorder(scheme).opacity(0.5), lineWidth: 1)
        )
    }
}

private struct GuideIconBadge: View {
    let systemName: String
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.14))
                .frame(width: 96, height: 96)
            Image(systemName: systemName)
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)
        }
    }
}

#Preview {
    AppGuideView(onFinish: {})
}
