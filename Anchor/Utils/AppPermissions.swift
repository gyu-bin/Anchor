//
//  AppPermissions.swift
//  Anchor
//

import FamilyControls
import UserNotifications

/// 첫 실행·가이드 완료 시 알림·스크린타임(잠금) 권한을 요청합니다.
@MainActor
enum AppPermissions {
    static func requestFamilyControlsIfNeeded() async {
        guard AuthorizationCenter.shared.authorizationStatus == .notDetermined else { return }
        try? await ShieldManager.requestAuthorization()
    }

    static func requestNotificationsIfNeeded() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = await NotificationManager.requestAuthorization()
    }

    /// 스크린타임(잠금) → 알림 순으로 시스템 권한을 요청합니다.
    static func requestEssentialPermissions() async {
        await requestFamilyControlsIfNeeded()
        try? await Task.sleep(for: .milliseconds(450))
        await requestNotificationsIfNeeded()
    }
}
