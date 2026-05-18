//
//  AppDelegate.swift
//  Anchor
//

import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.registerCategories()
        application.registerForRemoteNotifications()
        NotificationCenter.default.addObserver(
            forName: .anchorRegisterRemotePush,
            object: nil,
            queue: .main
        ) { _ in
            application.registerForRemoteNotifications()
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // 원격 푸시 서버 연동 시 deviceToken 전송
        _ = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        _ = error
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        DispatchQueue.main.async {
            if userInfo["openHistory"] as? Bool == true {
                NotificationCenter.default.post(name: .anchorOpenHistoryTab, object: nil)
            } else {
                NotificationCenter.default.post(name: .anchorOpenTodayTab, object: nil)
            }
            NotificationCenter.default.post(name: .anchorRefreshShield, object: nil)
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .anchorRefreshShield, object: nil)
        }
        completionHandler([.banner, .sound, .badge])
    }
}
