//
//  SettingsView.swift
//  Anchor
//

import FamilyControls
import SwiftData
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    @AppStorage(NotificationPreferencesKey.enabled) private var notificationsEnabled = true
    @AppStorage(NotificationPreferencesKey.routineStart) private var routineStartEnabled = true
    @AppStorage(NotificationPreferencesKey.reminder) private var reminderEnabled = true
    @AppStorage(NotificationPreferencesKey.weeklySummary) private var weeklySummaryEnabled = true
    @AppStorage("appearanceMode") private var appearanceModeRaw = AppearanceMode.system.rawValue

    @State private var showGuide = false
    @State private var shieldTitle: String = SharedShieldStore.shieldTitle
    @State private var shieldSubtitle: String = SharedShieldStore.shieldSubtitle
    @State private var screenTimeStatus: AuthorizationStatus = .notDetermined
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AnchorLayout.sectionSpacing) {
                    AnchorScreenHeader(title: AppCopy.Settings.title, subtitle: AppCopy.Settings.subtitle)

                    appearanceSection
                    guideSection
                    dataPrivacySection
                    notificationsSection
                    screenTimeSection
                    shieldMessageSection
                    aboutSection
                }
                .padding(.horizontal, AnchorLayout.screenHorizontal)
                .padding(.bottom, 36)
            }
            .anchorScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                screenTimeStatus = ShieldManager.authorizationStatus()
                refreshNotificationStatus()
                syncNotificationPrefs()
            }
            .onChange(of: notificationsEnabled) { _, _ in applyNotificationPrefs() }
            .onChange(of: routineStartEnabled) { _, _ in applyNotificationPrefs() }
            .onChange(of: reminderEnabled) { _, _ in applyNotificationPrefs() }
            .onChange(of: weeklySummaryEnabled) { _, _ in applyNotificationPrefs() }
            .fullScreenCover(isPresented: $showGuide) {
                AppGuideView(isReplay: true) {
                    showGuide = false
                }
            }
        }
    }

    private var appearanceSection: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 12) {
                AnchorSectionHeader(title: AppCopy.Settings.appearance)
                Picker(AppCopy.Settings.appearance, selection: $appearanceModeRaw) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(AnchorLayout.cardPadding)
        }
    }

    private var guideSection: some View {
        AnchorCard {
            Button {
                showGuide = true
            } label: {
                HStack {
                    Text(AppCopy.Guide.replay)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.anchorText(scheme))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.anchorSub(scheme))
                }
            }
            .buttonStyle(.plain)
            .padding(AnchorLayout.cardPadding)
        }
    }

    private var dataPrivacySection: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 8) {
                AnchorSectionHeader(title: AppCopy.Settings.dataPrivacy)
                Text(AppCopy.Settings.dataPrivacyBody)
                    .font(.subheadline)
                    .foregroundStyle(Color.anchorSub(scheme))
            }
            .padding(AnchorLayout.cardPadding)
        }
    }

    private var notificationsSection: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 14) {
                AnchorSectionHeader(title: AppCopy.Settings.notifications)

                Toggle(AppCopy.Settings.notificationsMaster, isOn: $notificationsEnabled)

                if notificationsEnabled {
                    Toggle(AppCopy.Settings.routineStart, isOn: $routineStartEnabled)
                    Toggle(AppCopy.Settings.reminder, isOn: $reminderEnabled)
                    Toggle(AppCopy.Settings.weeklySummary, isOn: $weeklySummaryEnabled)
                }

                Text(notificationStatusText)
                    .font(.caption)
                    .foregroundStyle(Color.anchorSub(scheme))

                Button(AppCopy.Settings.requestNotification) {
                    Task { await requestNotifications() }
                }
                .buttonStyle(AnchorSecondaryButtonStyle())
            }
            .padding(AnchorLayout.cardPadding)
        }
    }

    private var screenTimeSection: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 12) {
                AnchorSectionHeader(title: AppCopy.Settings.screenTime)

                HStack {
                    Text(screenTimeStatus == .approved ? AppCopy.Onboarding.screenTimeLinked : AppCopy.Onboarding.screenTimeNeeded)
                        .foregroundStyle(Color.anchorText(scheme))
                    Spacer()
                    Image(systemName: screenTimeStatus == .approved ? "checkmark.circle.fill" : "exclamationmark.circle")
                        .foregroundStyle(screenTimeStatus == .approved ? Color.anchorSuccess(scheme) : Color.anchorSub(scheme))
                }

                if screenTimeStatus != .approved {
                    Button(AppCopy.Onboarding.screenTimeAllow) {
                        Task {
                            try? await ShieldManager.requestAuthorization()
                            screenTimeStatus = ShieldManager.authorizationStatus()
                            await ShieldManager.refresh(modelContext: modelContext)
                        }
                    }
                    .buttonStyle(AnchorSecondaryButtonStyle())
                }
            }
            .padding(AnchorLayout.cardPadding)
        }
    }

    private var shieldMessageSection: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 12) {
                AnchorSectionHeader(
                    title: AppCopy.Settings.shieldTitle,
                    subtitle: AppCopy.Settings.shieldSubtitle
                )

                TextField(AppCopy.Settings.shieldTitlePlaceholder, text: $shieldTitle)
                    .anchorInsetField()
                TextField(AppCopy.Settings.shieldSubtitlePlaceholder, text: $shieldSubtitle)
                    .anchorInsetField()

                Button(AppCopy.Settings.shieldSave) {
                    let title = shieldTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    let subtitle = shieldSubtitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    SharedShieldStore.saveShieldMessages(
                        title: title.isEmpty ? SharedShieldStore.defaultShieldTitle : title,
                        subtitle: subtitle.isEmpty ? SharedShieldStore.defaultShieldSubtitle : subtitle
                    )
                }
                .buttonStyle(AnchorSecondaryButtonStyle())
            }
            .padding(AnchorLayout.cardPadding)
        }
    }

    private var aboutSection: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 10) {
                AnchorSectionHeader(title: AppCopy.Settings.about)
                Text(AppBrand.displayName)
                    .font(.headline)
                    .foregroundStyle(Color.anchorText(scheme))
                Text(AppCopy.Settings.aboutBody)
                    .font(.subheadline)
                    .foregroundStyle(Color.anchorSub(scheme))
                if let url = URL(string: "mailto:support@keyring.app") {
                    Link(AppCopy.Settings.contact, destination: url)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding(AnchorLayout.cardPadding)
        }
    }

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
        }
        refreshNotificationStatus()
        applyNotificationPrefs()
    }
}

enum NotificationPreferencesKey {
    static let enabled = "notifications.enabled"
    static let routineStart = "notifications.routineStart"
    static let reminder = "notifications.reminder"
    static let weeklySummary = "notifications.weeklySummary"
}
