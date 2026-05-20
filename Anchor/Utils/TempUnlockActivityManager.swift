
//
//  TempUnlockActivityManager.swift
//  Anchor
//

import ActivityKit
import Foundation

@MainActor
enum TempUnlockActivityManager {
    private static var currentActivity: Activity<TempUnlockAttributes>?

    static func start(expiresAt: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // 이미 실행 중인 Live Activity가 있으면 업데이트
        if let existing = currentActivity {
            Task {
                let state = TempUnlockAttributes.ContentState(expiresAt: expiresAt)
                let content = ActivityContent(state: state, staleDate: expiresAt)
                await existing.update(content)
            }
            return
        }

        let state = TempUnlockAttributes.ContentState(expiresAt: expiresAt)
        let content = ActivityContent(state: state, staleDate: expiresAt)

        do {
            currentActivity = try Activity<TempUnlockAttributes>.request(
                attributes: TempUnlockAttributes(),
                content: content,
                pushType: nil
            )
        } catch {
            #if DEBUG
            print("[TempUnlockActivity] 시작 실패: \(error)")
            #endif
        }
    }

    static func end() {
        guard let activity = currentActivity else { return }
        currentActivity = nil
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
