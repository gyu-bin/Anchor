//
//  SettingsView.swift
//  Anchor
//

import DeviceActivity
import FamilyControls
import SwiftData
import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @Environment(\.appStoreScreenshotExpandScreenTime) private var screenshotExpandScreenTime
    @EnvironmentObject private var premium: PremiumStore

    @AppStorage(NotificationPreferencesKey.enabled) private var notificationsEnabled = true
    @AppStorage(NotificationPreferencesKey.routineStart) private var routineStartEnabled = true
    @AppStorage(NotificationPreferencesKey.reminder) private var reminderEnabled = true
    @AppStorage(NotificationPreferencesKey.weeklySummary) private var weeklySummaryEnabled = true
    @AppStorage(NotificationPreferencesKey.reminderOffset) private var reminderOffsetMinutes = 30
    @AppStorage("appearanceMode") private var appearanceModeRaw = AppearanceMode.defaultMode.rawValue

    @State private var showGuide = false
    @State private var showScreenTime = false
    @State private var screenTimeStatus: AuthorizationStatus = .notDetermined
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var paywallReason: PaywallReason?
    @State private var bannerMessage: String?
    #if DEBUG
    @State private var devTapCount = 0
    #endif

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AnchorScreenHeader(title: AppCopy.Settings.title, subtitle: AppCopy.Settings.subtitle)

                    premiumSection

                    settingsGroup(AppCopy.Settings.sectionGeneral) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(AppCopy.Settings.appearance)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.anchorText(scheme))
                            Picker(AppCopy.Settings.appearance, selection: $appearanceModeRaw) {
                                ForEach(AppearanceMode.allCases) { mode in
                                    Text(mode.title).tag(mode.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                        .padding(AnchorLayout.cardPadding)

                        SettingsInsetDivider()

                        guideRow
                    }

                    settingsGroup(AppCopy.Settings.sectionNotifications) {
                        VStack(spacing: 0) {
                            Toggle(AppCopy.Settings.notificationsMaster, isOn: $notificationsEnabled)
                                .padding(.horizontal, AnchorLayout.cardPadding)
                                .padding(.vertical, 14)

                            if notificationsEnabled {
                                SettingsInsetDivider()

                                VStack(spacing: 0) {
                                    Toggle(AppCopy.Settings.routineStart, isOn: $routineStartEnabled)
                                        .padding(.horizontal, AnchorLayout.cardPadding)
                                        .padding(.vertical, 12)

                                    SettingsInsetDivider()

                                    HStack {
                                        Text(AppCopy.Settings.reminder)
                                        Spacer()
                                        if reminderEnabled {
                                            Picker("", selection: $reminderOffsetMinutes) {
                                                ForEach(NotificationPreferences.reminderOffsetChoices, id: \.minutes) { choice in
                                                    Text(choice.label).tag(choice.minutes)
                                                }
                                            }
                                            .labelsHidden()
                                            .pickerStyle(.menu)
                                        }
                                        Toggle("", isOn: $reminderEnabled)
                                            .labelsHidden()
                                            .fixedSize()
                                    }
                                    .padding(.horizontal, AnchorLayout.cardPadding)
                                    .padding(.vertical, 12)

                                    SettingsInsetDivider()
                                    weeklySummaryRow
                                        .padding(.horizontal, AnchorLayout.cardPadding)
                                        .padding(.vertical, 12)
                                }
                            }

                            SettingsInsetDivider()

                            VStack(alignment: .leading, spacing: 10) {
                                Text(notificationStatusText)
                                    .font(.caption)
                                    .foregroundStyle(Color.anchorSub(scheme))
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if notificationStatus == .denied {
                                    Button(AppCopy.Settings.openSystemSettings) {
                                        if let url = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                    .buttonStyle(AnchorSecondaryButtonStyle())
                                } else if notificationStatus != .authorized
                                    && notificationStatus != .provisional
                                    && notificationStatus != .ephemeral {
                                    Button(AppCopy.Settings.requestNotification) {
                                        Task { await requestNotifications() }
                                    }
                                    .buttonStyle(AnchorSecondaryButtonStyle())
                                }
                            }
                            .padding(AnchorLayout.cardPadding)
                        }
                    }

                    settingsGroup(AppCopy.Settings.sectionLock) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.anchorAccent(scheme))
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(AppCopy.Settings.lockTitle)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(Color.anchorText(scheme))
                                    Text(screenTimeStatus == .approved
                                         ? AppCopy.Onboarding.screenTimeLinked
                                         : AppCopy.Onboarding.screenTimeNeeded)
                                        .font(.caption)
                                        .foregroundStyle(Color.anchorSub(scheme))
                                }

                                Spacer(minLength: 8)

                                Text(screenTimeStatus == .approved
                                     ? AppCopy.Settings.lockConnected
                                     : AppCopy.Settings.lockNeeded)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(
                                        screenTimeStatus == .approved
                                            ? Color.anchorSuccess(scheme)
                                            : Color.anchorWarning(scheme)
                                    )
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        (screenTimeStatus == .approved
                                         ? Color.anchorSuccess(scheme)
                                         : Color.anchorWarning(scheme)).opacity(0.12)
                                    )
                                    .clipShape(Capsule())
                            }

                            if screenTimeStatus != .approved {
                                Button(AppCopy.Onboarding.screenTimeAllow) {
                                    requestScreenTimeAuthorization()
                                }
                                .buttonStyle(AnchorSecondaryButtonStyle())
                            }
                        }
                        .padding(AnchorLayout.cardPadding)
                    }

                    settingsGroup("스크린타임 사용 현황") {
                        VStack(spacing: 0) {
                            Button {
                                withAnimation(AnchorMotion.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showScreenTime.toggle()
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "hourglass")
                                        .font(.body)
                                        .foregroundStyle(Color.anchorAccent(scheme))
                                        .frame(width: 28)
                                    Text("스크린타임")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(Color.anchorText(scheme))
                                    Spacer(minLength: 8)
                                    Image(systemName: showScreenTime ? "chevron.up" : "chevron.down")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.anchorSub(scheme).opacity(0.7))
                                }
                                .padding(AnchorLayout.cardPadding)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(SettingsRowButtonStyle())

                            // 뷰를 파괴하지 않고 숨겨서 DeviceActivityReport가 계속 살아있게 유지
                            SettingsInsetDivider()
                                .frame(height: showScreenTime ? nil : 0)
                                .opacity(showScreenTime ? 1 : 0)
                                .clipped()
                            ScreenTimeReportSection(
                                authorizationStatus: screenTimeStatus,
                                onRequestAuthorization: requestScreenTimeAuthorization
                            )
                            .padding(.bottom, showScreenTime ? 4 : 0)
                            .frame(maxHeight: showScreenTime ? .infinity : 0)
                            .opacity(showScreenTime ? 1 : 0)
                            .clipped()
                        }
                    }

                    settingsGroup(AppCopy.Settings.sectionAbout) {
                        VStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(AppBrand.displayName)
                                    .font(.headline)
                                    .foregroundStyle(Color.anchorText(scheme))
                                Text(AppCopy.Settings.aboutBody)
                                    .font(.caption)
                                    .lineSpacing(3)
                                    .foregroundStyle(Color.anchorSub(scheme))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AnchorLayout.cardPadding)

                            SettingsInsetDivider()

                            SettingsValueRow(
                                title: AppCopy.Settings.versionRow,
                                value: AppInfo.versionLabel
                            )
                            #if DEBUG
                            .onTapGesture {
                                devTapCount += 1
                                if devTapCount >= 5 {
                                    devTapCount = 0
                                    let next = !PremiumStorage.isPremium
                                    PremiumStorage.setPremium(next)
                                    premium.syncFromStorage()
                                    bannerMessage = next ? "[DEV] 프리미엄 활성화됨" : "[DEV] 프리미엄 해제됨"
                                }
                            }
                            #endif

                            SettingsInsetDivider()

                            Link(destination: AppInfo.privacyPolicyURL) {
                                SettingsChevronRow(title: AppCopy.Settings.privacyPolicy)
                            }
                            .buttonStyle(.plain)

                            if let url = URL(string: "mailto:support@keyring.app") {
                                SettingsInsetDivider()
                                Link(destination: url) {
                                    SettingsChevronRow(title: AppCopy.Settings.contact)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, AnchorLayout.screenHorizontal)
                .padding(.bottom, bannerMessage == nil ? 36 : 88)
            }

            if let bannerMessage {
                AnchorBriefToast(message: bannerMessage)
                    .padding(.horizontal, AnchorLayout.screenHorizontal)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            }
            .anchorScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if screenshotExpandScreenTime {
                    showScreenTime = true
                    screenTimeStatus = .approved
                } else {
                    screenTimeStatus = ShieldManager.authorizationStatus()
                }
                refreshNotificationStatus()
                syncNotificationPrefs()
                if !premium.isPremium, weeklySummaryEnabled {
                    weeklySummaryEnabled = false
                    applyNotificationPrefs()
                }
            }
            .onChange(of: notificationsEnabled) { _, _ in applyNotificationPrefs() }
            .onChange(of: routineStartEnabled) { _, _ in applyNotificationPrefs() }
            .onChange(of: reminderEnabled) { _, _ in applyNotificationPrefs() }
            .onChange(of: weeklySummaryEnabled) { _, _ in applyNotificationPrefs() }
            .onChange(of: reminderOffsetMinutes) { _, _ in applyNotificationPrefs() }
            .fullScreenCover(isPresented: $showGuide) {
                AppGuideView(isReplay: true) {
                    showGuide = false
                }
            }
            .sheet(item: $paywallReason) { reason in
                PaywallSheet(reason: reason)
            }
        }
    }

    private func requestScreenTimeAuthorization() {
        Task {
            do {
                try await ShieldManager.requestAuthorization()
                screenTimeStatus = ShieldManager.authorizationStatus()
                if screenTimeStatus == .approved {
                    showBanner(nil)
                    RoutineSync.afterMutation(modelContext: modelContext)
                } else {
                    showBanner(AppCopy.Error.permissionFailed)
                }
            } catch {
                screenTimeStatus = ShieldManager.authorizationStatus()
                showBanner(AppCopy.Error.permissionFailed)
            }
        }
    }

    // MARK: - Sections

    private var premiumSection: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(AppCopy.Premium.settingsTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.anchorText(scheme))
                    Spacer()
                    if premium.isPremium {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.anchorSuccess(scheme))
                    }
                }

                if premium.isPremium {
                    Text(AppCopy.Premium.settingsUnlocked)
                        .font(.subheadline)
                        .foregroundStyle(Color.anchorSub(scheme))
                } else {
                    Text(AppCopy.Premium.settingsLocked)
                        .font(.subheadline)
                        .foregroundStyle(Color.anchorSub(scheme))

                    Button(AppCopy.Premium.settingsOpen) {
                        paywallReason = .general
                    }
                    .buttonStyle(AnchorButtonStyle())

                    Button(AppCopy.Premium.restore) {
                        Task { await premium.restore() }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.anchorAccent(scheme))
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(AnchorLayout.cardPadding)
        }
    }

    private var guideRow: some View {
        Button {
            showGuide = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "book.pages.fill")
                    .font(.body)
                    .foregroundStyle(Color.anchorAccent(scheme))
                    .frame(width: 28)

                Text(AppCopy.Guide.replay)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.anchorText(scheme))

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.anchorSub(scheme).opacity(0.7))
            }
            .padding(AnchorLayout.cardPadding)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(SettingsRowButtonStyle())
    }

    private var weeklySummaryRow: some View {
        Group {
            if premium.isPremium {
                Toggle(AppCopy.Settings.weeklySummary, isOn: $weeklySummaryEnabled)
            } else {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(AppCopy.Settings.weeklySummary)
                            .font(.body)
                            .foregroundStyle(Color.anchorText(scheme))
                        Text(AppCopy.Premium.weeklyLocked)
                            .font(.caption)
                            .foregroundStyle(Color.anchorSub(scheme))
                    }
                    Spacer(minLength: 8)
                    Button(AppCopy.Premium.settingsOpen) {
                        paywallReason = .weeklyNotification
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.anchorAccent(scheme))
                }
            }
        }
    }

    @ViewBuilder
    private func settingsGroup<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.anchorSub(scheme))
                .padding(.leading, 4)

            AnchorCard {
                content()
            }
        }
    }

    // MARK: - Helpers

    private var notificationStatusText: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            return AppCopy.Settings.notificationOn
        case .denied:
            return AppCopy.Settings.notificationDenied
        default:
            return AppCopy.Settings.notificationOff
        }
    }

    private func syncNotificationPrefs() {
        NotificationPreferences.notificationsEnabled = notificationsEnabled
        NotificationPreferences.routineStartEnabled = routineStartEnabled
        NotificationPreferences.reminderEnabled = reminderEnabled
        NotificationPreferences.weeklySummaryEnabled = weeklySummaryEnabled
        NotificationPreferences.reminderOffsetMinutes = reminderOffsetMinutes
    }

    private func applyNotificationPrefs() {
        syncNotificationPrefs()
        try? NotificationManager.rescheduleAll(modelContext: modelContext)
    }

    private func refreshNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }

    private func requestNotifications() async {
        let granted = await NotificationManager.requestAuthorization()
        if granted {
            NotificationCenter.default.post(name: .anchorRegisterRemotePush, object: nil)
            showBanner(nil)
        } else {
            showBanner(AppCopy.Error.permissionFailed)
        }
        refreshNotificationStatus()
        applyNotificationPrefs()
    }

    private func showBanner(_ message: String?) {
        if let message {
            withAnimation(AnchorMotion.spring(response: 0.32)) {
                bannerMessage = message
            }
            Task {
                try? await Task.sleep(for: .seconds(2.8))
                await MainActor.run {
                    withAnimation {
                        if bannerMessage == message {
                            bannerMessage = nil
                        }
                    }
                }
            }
        } else {
            withAnimation {
                bannerMessage = nil
            }
        }
    }
}

// MARK: - Settings rows

private struct SettingsInsetDivider: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Divider()
            .overlay(Color.anchorBorder(scheme).opacity(0.55))
            .padding(.leading, AnchorLayout.cardPadding)
    }
}

private struct SettingsValueRow: View {
    @Environment(\.colorScheme) private var scheme

    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundStyle(Color.anchorText(scheme))
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.anchorSub(scheme))
        }
        .padding(.horizontal, AnchorLayout.cardPadding)
        .padding(.vertical, 14)
    }
}

private struct SettingsChevronRow: View {
    @Environment(\.colorScheme) private var scheme

    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundStyle(Color.anchorAccent(scheme))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.anchorSub(scheme).opacity(0.7))
        }
        .padding(.horizontal, AnchorLayout.cardPadding)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

enum NotificationPreferencesKey {
    static let enabled = "notifications.enabled"
    static let routineStart = "notifications.routineStart"
    static let reminder = "notifications.reminder"
    static let weeklySummary = "notifications.weeklySummary"
    static let reminderOffset = "notifications.reminderOffsetMinutes"
}
