//
//  AnchorDesign.swift
//  Anchor
//

import SwiftUI

enum AnchorLayout {
    static let screenHorizontal: CGFloat = 20
    static let cardPadding: CGFloat = 18
    static let sectionSpacing: CGFloat = 20
    static let cardRadius: CGFloat = 20
    static let buttonRadius: CGFloat = 16
    static let chipRadius: CGFloat = 14
    static let rowRadius: CGFloat = 14
}

enum AnchorTypography {
    static func largeTitle(_ scheme: ColorScheme) -> Font {
        .system(size: 34, weight: .bold, design: .rounded)
    }

    static func screenTitle(_ scheme: ColorScheme) -> Font {
        .system(size: 28, weight: .bold, design: .default)
    }

    static func cardTitle(_ scheme: ColorScheme) -> Font {
        .system(size: 17, weight: .semibold)
    }

    static func metricValue(_ scheme: ColorScheme) -> Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }
}

struct AnchorScreenBackground: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    Color.anchorBg(scheme)
                    LinearGradient(
                        colors: [
                            Color.anchorAccent(scheme).opacity(0.04),
                            Color.clear,
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
                .ignoresSafeArea()
            }
    }
}

extension View {
    func anchorScreenBackground() -> some View {
        modifier(AnchorScreenBackground())
    }
}

struct AnchorSectionHeader: View {
    @Environment(\.colorScheme) private var scheme

    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.anchorText(scheme))
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.anchorSub(scheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AnchorScreenHeader: View {
    @Environment(\.colorScheme) private var scheme
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 28

    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: titleSize, weight: .bold, design: .default))
                .foregroundStyle(Color.anchorText(scheme))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.anchorSub(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .padding(.bottom, 4)
    }
}

struct OnboardingPageShell<Content: View>: View {
    @Environment(\.colorScheme) private var scheme

    let title: String
    let subtitle: String
    @ViewBuilder let content: Content
    let showsBack: Bool
    let primaryTitle: String
    let onBack: () -> Void
    let onPrimary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(AnchorTypography.screenTitle(scheme))
                    .foregroundStyle(Color.anchorText(scheme))
                Text(subtitle)
                    .font(.body)
                    .lineSpacing(3)
                    .foregroundStyle(Color.anchorSub(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            content

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                if showsBack {
                    Button(AppCopy.Common.back, action: onBack)
                        .buttonStyle(AnchorSecondaryButtonStyle())
                }
                Button(primaryTitle, action: onPrimary)
                    .buttonStyle(AnchorButtonStyle())
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

struct AnchorInsetField: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(Color.anchorSubBg(scheme))
            .clipShape(RoundedRectangle(cornerRadius: AnchorLayout.rowRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AnchorLayout.rowRadius, style: .continuous)
                    .strokeBorder(Color.anchorBorder(scheme).opacity(0.6), lineWidth: 1)
            )
    }
}

extension View {
    func anchorInsetField() -> some View {
        modifier(AnchorInsetField())
    }
}

struct AnchorSelectionRow: View {
    @Environment(\.colorScheme) private var scheme

    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(isSelected ? Color.anchorAccent(scheme) : Color.anchorSub(scheme))
                    .frame(width: 28)

                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.anchorText(scheme))

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.anchorAccent(scheme) : Color.anchorSub(scheme).opacity(0.35))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(isSelected ? Color.anchorAccent(scheme).opacity(0.08) : Color.anchorCard(scheme))
            .clipShape(RoundedRectangle(cornerRadius: AnchorLayout.rowRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AnchorLayout.rowRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.anchorAccent(scheme).opacity(0.35) : Color.anchorBorder(scheme).opacity(0.5),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct AnchorChip: View {
    @Environment(\.colorScheme) private var scheme

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? Color.anchorAccent(scheme) : Color.anchorText(scheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.anchorAccent(scheme).opacity(0.12) : Color.anchorSubBg(scheme))
            .clipShape(RoundedRectangle(cornerRadius: AnchorLayout.chipRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AnchorLayout.chipRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.anchorAccent(scheme).opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
