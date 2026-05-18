//
//  RestDayStore.swift
//  Anchor
//

import Foundation

/// 오늘은 쉼 — 연속 기록은 유지하고 잠금·완료 압박은 쉬어 갑니다.
enum RestDayStore {
    private static let restDayKey = "anchor.restDay"

    private static var suite: UserDefaults? {
        SharedShieldStore.suite
    }

    private static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func isRestDay(_ date: Date, calendar: Calendar = .current) -> Bool {
        suite?.string(forKey: restDayKey) == dayKey(for: date, calendar: calendar)
    }

    static func isRestToday(calendar: Calendar = .current) -> Bool {
        isRestDay(Date(), calendar: calendar)
    }

    static func setRestToday(calendar: Calendar = .current) {
        suite?.set(dayKey(for: Date(), calendar: calendar), forKey: restDayKey)
    }

    static func clearRestToday() {
        suite?.removeObject(forKey: restDayKey)
    }
}
