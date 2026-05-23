//
//  RoutineDeadlineExtensionStore.swift
//  Anchor
//

import Foundation

/// 오늘만 루틴 마감·잠금 해제 시각을 연장합니다 (루틴 `endTime`은 변경하지 않음).
enum RoutineDeadlineExtensionStore {
    static let minutesPerExtension = 30
    static let maxExtensionsPerRoutinePerDay = 2
    /// 마감 1시간 전부터 연장 버튼 노출
    static let offerWindowMinutesBeforeEnd = 60

    private static func minutesKey(dayKey: String, routineID: UUID) -> String {
        "deadline.extMin.\(dayKey).\(routineID.uuidString)"
    }

    private static func usesKey(dayKey: String, routineID: UUID) -> String {
        "deadline.extUses.\(dayKey).\(routineID.uuidString)"
    }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func extraMinutes(
        routineID: UUID,
        on day: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard calendar.isDateInToday(day) else { return 0 }
        let key = minutesKey(dayKey: dayKey(for: day, calendar: calendar), routineID: routineID)
        return max(0, SharedShieldStore.suite?.integer(forKey: key) ?? 0)
    }

    static func extensionsUsed(
        routineID: UUID,
        on day: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard calendar.isDateInToday(day) else { return 0 }
        let key = usesKey(dayKey: dayKey(for: day, calendar: calendar), routineID: routineID)
        return max(0, SharedShieldStore.suite?.integer(forKey: key) ?? 0)
    }

    static func remainingUses(
        routineID: UUID,
        on day: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        max(0, maxExtensionsPerRoutinePerDay - extensionsUsed(routineID: routineID, on: day, calendar: calendar))
    }

    @discardableResult
    static func applyExtension(
        routineID: UUID,
        minutes: Int = minutesPerExtension,
        on day: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard calendar.isDateInToday(day) else { return false }
        guard remainingUses(routineID: routineID, on: day, calendar: calendar) > 0 else { return false }

        let day = dayKey(for: day, calendar: calendar)
        let suite = SharedShieldStore.suite
        let minKey = minutesKey(dayKey: day, routineID: routineID)
        let useKey = usesKey(dayKey: day, routineID: routineID)
        let current = suite?.integer(forKey: minKey) ?? 0
        suite?.set(current + minutes, forKey: minKey)
        let uses = suite?.integer(forKey: useKey) ?? 0
        suite?.set(uses + 1, forKey: useKey)
        return true
    }
}
