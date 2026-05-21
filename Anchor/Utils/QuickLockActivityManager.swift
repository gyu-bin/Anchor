//
//  QuickLockActivityManager.swift
//  Anchor
//

import ActivityKit
import Foundation

@MainActor
enum QuickLockActivityManager {
    private static var currentActivity: Activity<QuickLockAttributes>?

    static func start(expiresAt: Date, appCount: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = QuickLockAttributes.ContentState(expiresAt: expiresAt, appCount: appCount)
        let content = ActivityContent(state: state, staleDate: expiresAt)

        // 이미 실행 중이면 업데이트
        if let existing = currentActivity {
            Task { await existing.update(content) }
            return
        }

        do {
            currentActivity = try Activity<QuickLockAttributes>.request(
                attributes: QuickLockAttributes(),
                content: content,
                pushType: nil
            )
        } catch {
            #if DEBUG
            print("[QuickLockActivityManager] start failed: \(error)")
            #endif
        }
    }

    static func end() {
        currentActivity = nil
        let activities = Activity<QuickLockAttributes>.activities
        guard !activities.isEmpty else { return }
        Task {
            for activity in activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
