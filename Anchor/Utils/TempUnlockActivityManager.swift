
//
//  TempUnlockActivityManager.swift
//  Anchor
//

import ActivityKit
import Foundation

@MainActor
enum TempUnlockActivityManager {
    private static var currentActivity: Activity<TempUnlockAttributes>?

    static var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// 10분 해제 시작·앱 재실행 시 Dynamic Island / 잠금 화면 타이머를 띄웁니다.
    static func start(expiresAt: Date) {
        guard expiresAt > Date() else {
            end()
            return
        }

        guard areActivitiesEnabled else {
            #if DEBUG
            print("[TempUnlockActivity] Live Activities가 설정에서 꺼져 있어요")
            #endif
            return
        }

        QuickLockActivityManager.end()

        let state = TempUnlockAttributes.ContentState(expiresAt: expiresAt)
        let content = ActivityContent(state: state, staleDate: expiresAt)

        if let existing = currentActivity ?? Activity<TempUnlockAttributes>.activities.first {
            currentActivity = existing
            Task { await existing.update(content) }
            return
        }

        endStaleActivities()

        do {
            currentActivity = try Activity<TempUnlockAttributes>.request(
                attributes: TempUnlockAttributes(),
                content: content,
                pushType: nil
            )
            #if DEBUG
            print("[TempUnlockActivity] 시작됨, 만료: \(expiresAt)")
            #endif
        } catch {
            #if DEBUG
            print("[TempUnlockActivity] 시작 실패: \(error)")
            #endif
        }
    }

    static func end() {
        currentActivity = nil
        endStaleActivities()
    }

    /// 오늘 탭 등에서 만료된 Activity 정리
    static func reconcile(expiresAt: Date?) {
        guard let expiresAt, expiresAt > Date(), TempUnlockStore.isActive else {
            end()
            return
        }
        start(expiresAt: expiresAt)
    }

    private static func endStaleActivities() {
        let activities = Activity<TempUnlockAttributes>.activities
        guard !activities.isEmpty else { return }
        Task {
            for activity in activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
