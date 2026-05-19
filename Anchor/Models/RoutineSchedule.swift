//
//  RoutineSchedule.swift
//  Anchor
//

import Foundation
import SwiftData

enum RoutineScheduleKind: String, CaseIterable, Identifiable, Codable {
    case daily
    case weekdays
    case once

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return AppCopy.Routine.ScheduleKind.daily
        case .weekdays: return AppCopy.Routine.ScheduleKind.weekdays
        case .once: return AppCopy.Routine.ScheduleKind.once
        }
    }
}

struct RoutineScheduleDraft: Equatable {
    var kind: RoutineScheduleKind = .daily
    var activeWeekdays: Set<Int> = [2, 3, 4, 5, 6]
    var oneTimeDate: Date = Date()
    var startTime: Date = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()
    var hasEndTime: Bool = false
    var endTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
}

enum RoutineSchedule {
    /// `Calendar.weekday`: 1=일 … 7=토
    static let weekdayOptions: [(Int, String)] = [
        (1, "일"), (2, "월"), (3, "화"), (4, "수"),
        (5, "목"), (6, "금"), (7, "토"),
    ]

    static let allWeekdays: Set<Int> = Set(1...7)

    static func apply(_ draft: RoutineScheduleDraft, to routine: Routine, calendar: Calendar = .current) {
        routine.scheduleKindRaw = draft.kind.rawValue
        routine.startTime = draft.startTime
        routine.endTime = draft.hasEndTime ? draft.endTime : nil
        switch draft.kind {
        case .daily:
            routine.activeWeekdays = Array(allWeekdays).sorted()
            routine.oneTimeDate = nil
        case .weekdays:
            routine.activeWeekdays = Array(draft.activeWeekdays).sorted()
            routine.oneTimeDate = nil
        case .once:
            routine.activeWeekdays = []
            routine.oneTimeDate = draft.oneTimeDate.startOfDay(in: calendar)
        }
    }

    static func draft(from routine: Routine, calendar: Calendar = .current) -> RoutineScheduleDraft {
        var draft = RoutineScheduleDraft()
        draft.kind = routine.scheduleKind
        draft.activeWeekdays = Set(activeWeekdays(for: routine))
        draft.oneTimeDate = routine.oneTimeDate ?? Date()
        draft.startTime = routine.startTime
        draft.hasEndTime = routine.endTime != nil
        draft.endTime = routine.endTime ?? (calendar.date(bySettingHour: 9, minute: 0, second: 0, of: routine.startTime) ?? routine.startTime)
        return draft
    }

    /// 저장값이 없으면 일정 종류에 맞는 기본 요일을 돌려줍니다.
    static func activeWeekdays(for routine: Routine) -> [Int] {
        if let stored = routine.activeWeekdays, !stored.isEmpty {
            return stored
        }
        switch routine.scheduleKind {
        case .daily:
            return Array(1...7)
        case .weekdays:
            return [2, 3, 4, 5, 6]
        case .once:
            return []
        }
    }

    /// 스키마 추가 이전에 저장된 루틴에 기본 일정 값을 채웁니다.
    @MainActor
    static func repairLegacyRoutines(in context: ModelContext) {
        guard let routines = try? context.fetch(FetchDescriptor<Routine>()) else { return }
        var changed = false
        for routine in routines {
            if routine.scheduleKindRaw == nil {
                routine.scheduleKindRaw = RoutineScheduleKind.daily.rawValue
                changed = true
            }
            if routine.activeWeekdays == nil {
                routine.activeWeekdays = activeWeekdays(for: routine)
                changed = true
            }
            if routine.createdAt == nil {
                let fd = FetchDescriptor<DailyLog>()
                let logs = (try? context.fetch(fd)) ?? []
                routine.createdAt = effectiveCreatedDay(for: routine, logs: logs)
                changed = true
            }
        }
        if changed {
            try? context.save()
        }
    }

    static func isActive(_ routine: Routine, on date: Date, calendar: Calendar = .current) -> Bool {
        let day = date.startOfDay(in: calendar)
        switch routine.scheduleKind {
        case .daily:
            return true
        case .weekdays:
            let weekday = calendar.component(.weekday, from: day)
            return activeWeekdays(for: routine).contains(weekday)
        case .once:
            guard let once = routine.oneTimeDate else { return false }
            return calendar.isDate(day, inSameDayAs: calendar.startOfDay(for: once))
        }
    }

    /// 잠금·위젯·알림 등 — 오늘 일정이고 항목이 있을 때만
    static func isVisibleToday(_ routine: Routine, calendar: Calendar = .current) -> Bool {
        guard !routine.items.isEmpty else { return false }
        return isActive(routine, on: Date(), calendar: calendar)
    }

    static func scheduledRoutines(
        _ routines: [Routine],
        on day: Date,
        calendar: Calendar = .current
    ) -> [Routine] {
        routines.filter { !$0.items.isEmpty && isActive($0, on: day, calendar: calendar) }
    }

    /// 그날 일정이 있고, 루틴이 이미 만들어진 뒤인 날만 (생성일 이전은 제외).
    static func scheduledRoutinesExisting(
        _ routines: [Routine],
        logs: [DailyLog],
        on day: Date,
        calendar: Calendar = .current
    ) -> [Routine] {
        let dayStart = day.startOfDay(in: calendar)
        return scheduledRoutines(routines, on: day, calendar: calendar).filter { routine in
            effectiveCreatedDay(for: routine, logs: logs, calendar: calendar) <= dayStart
        }
    }

    static func effectiveCreatedDay(
        for routine: Routine,
        logs: [DailyLog],
        calendar: Calendar = .current
    ) -> Date {
        if let created = routine.createdAt {
            return calendar.startOfDay(for: created)
        }
        if let earliest = logs
            .filter({ $0.routineId == routine.id })
            .map({ calendar.startOfDay(for: $0.date) })
            .min() {
            return earliest
        }
        return calendar.startOfDay(for: Date())
    }

    static let weekdaySet: Set<Int> = [2, 3, 4, 5, 6]
    static let weekendSet: Set<Int> = [1, 7]

    static func weekdaySummary(_ weekdays: [Int]) -> String {
        let set = Set(weekdays)
        if set == allWeekdays { return AppCopy.Routine.repeatsDaily }
        if set == weekdaySet   { return "평일" }
        if set == weekendSet   { return "주말" }
        let labels = weekdayOptions
            .filter { set.contains($0.0) }
            .map(\.1)
        return labels.isEmpty ? AppCopy.Routine.ScheduleKind.weekdays : labels.joined()
    }

    static func cardSubtitle(for routine: Routine, itemCount: Int, startTimeText: String) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "a h:mm"
        let timePart: String
        if let end = routine.endTime {
            timePart = "\(startTimeText) ~ \(df.string(from: end))"
        } else {
            timePart = startTimeText
        }

        let schedulePart: String
        switch routine.scheduleKind {
        case .daily:
            schedulePart = AppCopy.Routine.repeatsDaily
        case .weekdays:
            schedulePart = weekdaySummary(activeWeekdays(for: routine))
        case .once:
            df.setLocalizedDateFormatFromTemplate("MMMd")
            let date = routine.oneTimeDate ?? Date()
            schedulePart = "\(AppCopy.Routine.ScheduleKind.onceShort) \(df.string(from: date))"
        }
        if itemCount == 0 {
            return "\(schedulePart) · \(timePart)"
        }
        var parts = [schedulePart, "\(itemCount)개 항목"]
        if let duration = RoutineDuration.formattedTotal(items: routine.items) {
            parts.append(duration)
        }
        parts.append(timePart)
        return parts.joined(separator: " · ")
    }
}

extension Routine {
    var scheduleKind: RoutineScheduleKind {
        get {
            RoutineScheduleKind(rawValue: scheduleKindRaw ?? RoutineScheduleKind.daily.rawValue) ?? .daily
        }
        set { scheduleKindRaw = newValue.rawValue }
    }
}
