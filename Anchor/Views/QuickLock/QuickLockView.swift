
//
//  QuickLockView.swift
//  Anchor
//

import FamilyControls
import ManagedSettings
import SwiftData
import SwiftUI

struct QuickLockView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var premium: PremiumStore

    private let durations = [15, 30, 60, 120]

    @State private var selectedDuration = 30
    @State private var showingPicker = false
    @State private var paywallReason: PaywallReason?
    @State private var selection: FamilyActivitySelection = {
        ShieldManager.decodeSelection(QuickLockStore.selectionData)
    }()
    @State private var isActive = QuickLockStore.isActive
    @State private var remainingSeconds = QuickLockStore.remainingSeconds
    @State private var timerTask: Task<Void, Never>?
    @State private var authStatus = ShieldManager.authorizationStatus()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AnchorScreenHeader(
                    title: AppCopy.Today.quickLockButton,
                    subtitle: AppCopy.QuickLock.subtitle
                )

                if isActive {
                    activeSection
                } else {
                    setupSection
                }
            }
            .padding(.horizontal, AnchorLayout.screenHorizontal)
            .padding(.bottom, 36)
        }
        .anchorScreenBackground()
        .familyActivityPicker(isPresented: $showingPicker, selection: $selection)
        .onChange(of: selection) { _, _ in
            QuickLockStore.selectionData = try? PropertyListEncoder().encode(selection)
        }
        .sheet(item: $paywallReason) { reason in
            PaywallSheet(reason: reason)
        }
        .onAppear {
            authStatus = ShieldManager.authorizationStatus()
            isActive = QuickLockStore.isActive
            remainingSeconds = QuickLockStore.remainingSeconds
            if isActive { startCountdown() }
        }
        .onDisappear {
            timerTask?.cancel()
        }
    }

    // MARK: - Active

    private var activeSection: some View {
        VStack(spacing: 16) {
            AnchorCard {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.anchorAccent(scheme).opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(Color.anchorAccent(scheme))
                    }

                    VStack(spacing: 6) {
                        Text(formatTime(remainingSeconds))
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.anchorText(scheme))
                            .monospacedDigit()
                        Text("후 자동 해제")
                            .font(.subheadline)
                            .foregroundStyle(Color.anchorSub(scheme))
                    }

                    Button("지금 해제") { handleDeactivate() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.anchorAccent(scheme))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.anchorAccent(scheme).opacity(0.1))
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, AnchorLayout.cardPadding)
            }

            let appTokens = Array(selection.applicationTokens)
            let webTokens = Array(selection.webDomainTokens)
            if !appTokens.isEmpty || !webTokens.isEmpty {
                AnchorCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("잠긴 앱")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.anchorSub(scheme))
                            .padding(.horizontal, AnchorLayout.cardPadding)
                            .padding(.top, AnchorLayout.cardPadding)

                        if !appTokens.isEmpty {
                            let visible = Array(appTokens.prefix(8))
                            let extra = appTokens.count - visible.count
                            VStack(spacing: 0) {
                                ForEach(Array(visible.enumerated()), id: \.offset) { idx, token in
                                    HStack(spacing: 10) {
                                        Label(token)
                                            .labelStyle(.iconOnly)
                                            .frame(width: 30, height: 30)
                                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                                        Label(token)
                                            .labelStyle(.titleOnly)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.anchorText(scheme))
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(.horizontal, AnchorLayout.cardPadding)
                                    .padding(.vertical, 8)

                                    if idx < visible.count - 1 || extra > 0 {
                                        Divider()
                                            .padding(.leading, AnchorLayout.cardPadding + 40)
                                    }
                                }
                                if extra > 0 {
                                    Text("외 \(extra)개 앱")
                                        .font(.caption)
                                        .foregroundStyle(Color.anchorSub(scheme))
                                        .padding(.horizontal, AnchorLayout.cardPadding)
                                        .padding(.vertical, 8)
                                }
                            }
                        }

                        if !webTokens.isEmpty {
                            if !appTokens.isEmpty {
                                Divider().padding(.horizontal, AnchorLayout.cardPadding)
                            }
                            HStack(spacing: 8) {
                                Image(systemName: "globe")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.anchorSub(scheme))
                                    .frame(width: 30)
                                Text("웹 \(webTokens.count)개")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.anchorText(scheme))
                                Spacer()
                            }
                            .padding(.horizontal, AnchorLayout.cardPadding)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.bottom, AnchorLayout.cardPadding)
                }
            }
        }
    }

    // MARK: - Setup

    private var setupSection: some View {
        VStack(spacing: 16) {
            if authStatus != .approved {
                AnchorCard {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.title3)
                            .foregroundStyle(Color.anchorWarning(scheme))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("스크린타임 권한 필요")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.anchorText(scheme))
                            Text("앱 잠금을 사용하려면 스크린타임 권한이 필요해요")
                                .font(.caption)
                                .foregroundStyle(Color.anchorSub(scheme))
                        }
                        Spacer()
                    }
                    .padding(AnchorLayout.cardPadding)
                }

                Button(AppCopy.Onboarding.screenTimeAllow) {
                    Task {
                        try? await ShieldManager.requestAuthorization()
                        authStatus = ShieldManager.authorizationStatus()
                    }
                }
                .buttonStyle(AnchorButtonStyle())
            } else {
                // App selection
                AnchorCard {
                    Button { showingPicker = true } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "apps.iphone")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.anchorAccent(scheme))
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("잠글 앱 선택")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color.anchorText(scheme))
                                Text(selectionSummary.isEmpty ? "탭해서 앱을 선택해요" : selectionSummary)
                                    .font(.caption)
                                    .foregroundStyle(
                                        isOverAppLimit ? Color.anchorWarning(scheme) : Color.anchorSub(scheme)
                                    )
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.anchorSub(scheme))
                        }
                        .padding(AnchorLayout.cardPadding)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if isOverAppLimit {
                        Divider().padding(.leading, AnchorLayout.cardPadding)
                        Button {
                            paywallReason = .appLimit
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                Text(AppCopy.Premium.quickLockAppLimitHint)
                                    .font(.caption)
                                Spacer()
                                Text("전체 기능 열기")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(Color.anchorAccent(scheme))
                            .padding(.horizontal, AnchorLayout.cardPadding)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Duration
                AnchorCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("잠금 시간")
                            .font(AnchorTypography.cardTitle(scheme))
                            .foregroundStyle(Color.anchorText(scheme))

                        HStack(spacing: 8) {
                            ForEach(durations, id: \.self) { min in
                                Button {
                                    selectedDuration = min
                                } label: {
                                    Text(durationLabel(min))
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            selectedDuration == min
                                                ? Color.anchorAccent(scheme)
                                                : Color.anchorSubBg(scheme)
                                        )
                                        .foregroundStyle(
                                            selectedDuration == min
                                                ? Color.white
                                                : Color.anchorText(scheme)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                        }
                    }
                    .padding(AnchorLayout.cardPadding)
                }

                Button {
                    if isOverAppLimit {
                        paywallReason = .appLimit
                    } else {
                        handleActivate()
                    }
                } label: {
                    Label("지금 잠금", systemImage: "lock.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AnchorButtonStyle())
                .disabled(!hasSelection)

                if !hasSelection {
                    Text("잠글 앱을 먼저 선택해 주세요")
                        .font(.caption)
                        .foregroundStyle(Color.anchorSub(scheme))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    // MARK: - Helpers

    private var hasSelection: Bool {
        !selection.applicationTokens.isEmpty || !selection.webDomainTokens.isEmpty
    }

    private var isOverAppLimit: Bool {
        !premium.isPremium && selection.applicationTokens.count > PremiumLimits.maxQuickLockApps
    }

    private var selectionSummary: String {
        let apps = selection.applicationTokens.count
        let webs = selection.webDomainTokens.count
        guard apps > 0 || webs > 0 else { return "" }
        var parts: [String] = []
        if apps > 0 { parts.append("앱 \(apps)개") }
        if webs > 0 { parts.append("웹 \(webs)개") }
        return parts.joined(separator: ", ") + " 선택됨"
    }

    private func durationLabel(_ minutes: Int) -> String {
        minutes < 60 ? "\(minutes)분" : "\(minutes / 60)시간"
    }

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }

    private func handleActivate() {
        let expiresAt = Date().addingTimeInterval(TimeInterval(selectedDuration * 60))
        QuickLockStore.activate(minutes: selectedDuration)
        isActive = true
        remainingSeconds = QuickLockStore.remainingSeconds
        TempUnlockActivityManager.end()
        QuickLockActivityManager.start(
            expiresAt: expiresAt,
            appCount: selection.applicationTokens.count
        )
        Task { await ShieldManager.refresh(modelContext: modelContext) }
        startCountdown()
    }

    private func handleDeactivate() {
        timerTask?.cancel()
        timerTask = nil
        QuickLockStore.deactivate()
        isActive = false
        remainingSeconds = 0
        QuickLockActivityManager.end()
        Task { await ShieldManager.refresh(modelContext: modelContext) }
    }

    private func startCountdown() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                let remaining = QuickLockStore.remainingSeconds
                remainingSeconds = remaining
                if remaining == 0 {
                    QuickLockStore.deactivate()
                    isActive = false
                    QuickLockActivityManager.end()
                    await ShieldManager.refresh(modelContext: modelContext)
                    break
                }
            }
        }
    }
}
