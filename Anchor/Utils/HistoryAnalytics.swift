//
//  HistoryAnalytics.swift
//  Anchor
//

import Foundation
import SwiftData

struct ItemTotalRow: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let count: Int

    var formatted: String {
        "\(count)회"
    }
}

struct MonthCompletionSummary {
    let completedSlots: Int
    let scheduledSlots: Int

    var percent: Int {
        guard scheduledSlots > 0 else { return 0 }
        return Int((Double(completedSlots) / Double(scheduledSlots) * 100.0).rounded())
    }
}

enum HistoryAnalytics {
    static func dayStatus(logs: [DailyLog], routines: [Routine], day: Date, cal: Calendar) -> WeekdayCompletion {
        if RoutineDeadline.isFutureDay(day, calendar: cal) { return .none }

        let scheduled = RoutineSchedule.scheduledRoutinesExisting(
            routines,
            logs: logs,
            on: day,
            calendar: cal
        )
        guard !scheduled.isEmpty else { return .none }
        if RestDayStore.isRestDay(day, calendar: cal) { return .full }

        let allFull = !scheduled.contains {
            !RoutineDeadline.isFullyComplete($0, logs: logs, day: day, calendar: cal)
        }
        if allFull { return .full }

        if RoutineDeadline.isReadyToJudgeIncomplete(
            scheduled: scheduled,
            logs: logs,
            day: day,
            calendar: cal
        ) {
            return .missedDeadline
        }
        return .none
    }

    static func missedDeadlineDaysInMonth(
        logs: [DailyLog],
        routines: [Routine],
        monthStart: Date,
        cal: Calendar
    ) -> Int {
        guard let range = cal.range(of: .day, in: .month, for: monthStart) else { return 0 }
        var count = 0
        let todayStart = cal.startOfDay(for: Date())
        for day in range {
            guard let d = cal.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            guard cal.startOfDay(for: d) <= todayStart else { continue }
            if dayStatus(logs: logs, routines: routines, day: d, cal: cal) == .missedDeadline {
                count += 1
            }
        }
        return count
    }

    static func weekFullDaysCount(logs: [DailyLog], routines: [Routine], now: Date, cal: Calendar) -> Int {
        weekBars(logs: logs, routines: routines, now: now, cal: cal)
            .filter { $0.status == .full }
            .count
    }

    static func weekBars(logs: [DailyLog], routines: [Routine], now: Date, cal: Calendar) -> [WeekdayBar] {
        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = TimeZone.current
        let weekStart = iso.date(from: iso.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now

        let labels = ["월", "화", "수", "목", "금", "토", "일"]
        return (0..<7).map { idx in
            let day = iso.date(byAdding: .day, value: idx, to: weekStart) ?? now
            let status = dayStatus(logs: logs, routines: routines, day: day, cal: iso)
            let value: Double
            switch status {
            case .full:
                value = 3
            case .missedDeadline:
                value = 1.2
            case .none:
                value = 0.6
            }
            return WeekdayBar(label: labels[idx], value: value, status: status)
        }
    }

    static func bestStreak(logs: [DailyLog], routines: [Routine], cal: Calendar) -> Int {
        guard !routines.isEmpty else { return 0 }

        let today = cal.startOfDay(for: Date())
        var earliest = today
        for log in logs {
            let d = cal.startOfDay(for: log.date)
            if d < earliest { earliest = d }
        }

        var best = 0
        var current = 0
        var day = earliest
        while day <= today {
            let scheduled = RoutineSchedule.scheduledRoutines(routines, on: day, calendar: cal)
            let countsAsSuccess: Bool
            if scheduled.isEmpty {
                countsAsSuccess = true
            } else {
                countsAsSuccess = dayStatus(logs: logs, routines: routines, day: day, cal: cal) == .full
            }
            if countsAsSuccess {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return best
    }

    static func streak(logs: [DailyLog], routines: [Routine], cal: Calendar) -> Int {
        guard !routines.isEmpty else { return 0 }
        var count = 0
        var day = cal.startOfDay(for: Date())
        while true {
            let scheduled = RoutineSchedule.scheduledRoutines(routines, on: day, calendar: cal)
            let status: WeekdayCompletion
            if scheduled.isEmpty {
                status = .full
            } else {
                status = dayStatus(logs: logs, routines: routines, day: day, cal: cal)
            }
            if status == .full {
                count += 1
            } else {
                break
            }
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    /// 이번 달 1일~오늘, 루틴이 있던 날의 「예정 루틴」 칸 중 전부 완료한 비율.
    static func monthCompletionSummary(
        logs: [DailyLog],
        routines: [Routine],
        now: Date,
        cal: Calendar
    ) -> MonthCompletionSummary {
        guard !routines.isEmpty else {
            return MonthCompletionSummary(completedSlots: 0, scheduledSlots: 0)
        }
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let monthStart = cal.date(from: comps),
              let monthRange = cal.range(of: .day, in: .month, for: monthStart) else {
            return MonthCompletionSummary(completedSlots: 0, scheduledSlots: 0)
        }

        let todayStart = cal.startOfDay(for: now)
        let todayDay = cal.component(.day, from: now)

        var completedSlots = 0
        var scheduledSlots = 0
        for day in monthRange where day <= todayDay {
            guard let d = cal.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            if d > todayStart { break }
            if RestDayStore.isRestDay(d, calendar: cal) { continue }

            let scheduled = RoutineSchedule.scheduledRoutinesExisting(
                routines,
                logs: logs,
                on: d,
                calendar: cal
            )
            guard !scheduled.isEmpty else { continue }

            scheduledSlots += scheduled.count
            let start = d.startOfDay(in: cal)
            let dayLogs = logs.filter { cal.isDate($0.date, inSameDayAs: start) }
            let map = Dictionary(uniqueKeysWithValues: dayLogs.map { ($0.routineId, $0) })
            for r in scheduled {
                if let log = map[r.id], log.isFullyCompleted {
                    completedSlots += 1
                }
            }
        }
        return MonthCompletionSummary(completedSlots: completedSlots, scheduledSlots: scheduledSlots)
    }

    static func monthCompletionRate(logs: [DailyLog], routines: [Routine], now: Date, cal: Calendar) -> Int {
        monthCompletionSummary(logs: logs, routines: routines, now: now, cal: cal).percent
    }

    static func itemCompletionCounts(logs: [DailyLog], routines: [Routine]) -> [ItemTotalRow] {
        var totals: [UUID: (name: String, icon: String, count: Int)] = [:]

        let itemById: [UUID: RoutineItem] = routines
            .flatMap(\.items)
            .reduce(into: [:]) { $0[$1.id] = $1 }

        for log in logs {
            for itemId in log.completedItems {
                guard let item = itemById[itemId] else { continue }
                let prev = totals[itemId]?.count ?? 0
                totals[itemId] = (item.name, item.icon, prev + 1)
            }
        }

        return totals
            .map { id, v in ItemTotalRow(id: id, name: v.name, icon: v.icon, count: v.count) }
            .sorted { $0.count > $1.count }
    }
}
