//
//  DeadlineGraceStore.swift
//  Anchor
//

import Foundation

/// 종료 시각까지 미완료 시 잠금 해제 유예 — 3회까지는 마감 즉시, 4회째부터 마감 30분 후.
enum DeadlineGraceStore {
    private static let missCountKey = "deadline.graceMissCount"
    private static let lastRecordedDayKey = "deadline.lastRecordedDayKey"

    static let maxImmediateUnlockMisses = 3
    static let delayedUnlockMinutes = 30

    static var missCount: Int {
        max(0, SharedShieldStore.suite?.integer(forKey: missCountKey) ?? 0)
    }

    static func resetMissCount() {
        SharedShieldStore.suite?.set(0, forKey: missCountKey)
        SharedShieldStore.suite?.removeObject(forKey: lastRecordedDayKey)
    }

    /// 오늘 아직 기록하지 않았고, 마감이 지난 미완료 루틴이 있으면 1회 카운트.
    static func recordMissForTodayIfNeeded(dayKey: String) {
        let suite = SharedShieldStore.suite
        if suite?.string(forKey: lastRecordedDayKey) == dayKey { return }
        let next = missCount + 1
        suite?.set(next, forKey: missCountKey)
        suite?.set(dayKey, forKey: lastRecordedDayKey)
    }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
