//
//  TodayEmptyHintStore.swift
//  Anchor
//

import Foundation

/// 오늘 탭 「일정 없음」 안내를 처음 한 번만 보여 줍니다.
enum TodayEmptyHintStore {
    private static let hasSeenKey = "anchor.todayEmptyScheduleHintSeen"

    static var shouldShow: Bool {
        !UserDefaults.standard.bool(forKey: hasSeenKey)
    }

    static func markSeen() {
        UserDefaults.standard.set(true, forKey: hasSeenKey)
    }
}
