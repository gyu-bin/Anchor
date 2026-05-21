//
//  RoutineSchedule.swift
//  Anchor
//

import Foundation
import SwiftData

enum RoutineScheduleKind: String, CaseIterable, Identifiable, Codable {
    case daily
    case weekdays
    case period
    case once

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return AppCopy.Routine.ScheduleKind.daily
        case .weekdays: return AppCopy.Routine.ScheduleKind.weekdays
        case .period: return AppCopy.Routine.ScheduleKind.period
        case .once: return AppCopy.Routine.ScheduleKind.once
        }
    }
}

enum RoutineExpiryAction: String, CaseIterable, Identifiable, Codable {
    case keepInList
    case archive
    case delete

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keepInList: return AppCopy.Routine.Expiry.keepInList
        case .archive: return AppCopy.Routine.Expiry.archive
        case .delete: return AppCopy.Routine.Expiry.delete
        }
    }
}

struct RoutineScheduleDraft: Equatable {
    var kind: RoutineScheduleKind = .daily
    var activeWeekdays: Set<Int> = [2, 3, 4, 5, 6]
    var oneTimeDate: Date = Date()
    var scheduleStartDate: Date = Date()
    var scheduleEndDate: Date = Date()
    var hasScheduleEnd: Bool = false
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
            routine.scheduleStartDate = nil
            routine.scheduleEndDate = draft.hasScheduleEnd
                ? draft.scheduleEndDate.startOfDay(in: calendar)
                : nil
        case .weekdays:
            routine.activeWeekdays = Array(draft.activeWeekdays).sorted()
            routine.oneTimeDate = nil
            routine.scheduleStartDate = nil
            routine.scheduleEndDate = draft.hasScheduleEnd
                ? draft.scheduleEndDate.startOfDay(in: calendar)
                : nil
        case .period:
            let start = draft.scheduleStartDate.startOfDay(in: calendar)
            let end = draft.scheduleEndDate.startOfDay(in: calendar)
            routine.scheduleStartDate = start
            routine.scheduleEndDate = end
            routine.oneTimeDate = nil
            if draft.activeWeekdays.isEmpty {
                routine.activeWeekdays = []
            } else {
                routine.activeWeekdays = Array(draft.activeWeekdays).sorted()
            }
        case .once:
            let day = draft.oneTimeDate.startOfDay(in: calendar)
            routine.activeWeekdays = []
            routine.oneTimeDate = day
            routine.scheduleStartDate = day
            routine.scheduleEndDate = day
        }
    }

    static func draft(from routine: Routine, calendar: Calendar = .current) -> RoutineScheduleDraft {
        var draft = RoutineScheduleDraft()
        draft.kind = routine.scheduleKind
        draft.activeWeekdays = Set(activeWeekdays(for: routine))
        draft.oneTimeDate = routine.oneTimeDate ?? Date()
        draft.scheduleStartDate = routine.scheduleStartDate ?? Date()
        draft.scheduleEndDate = routine.scheduleEndDate ?? Date()
        draft.hasScheduleEnd = routine.scheduleEndDate != nil
            && routine.scheduleKind != .once
            && routine.scheduleKind != .period
        draft.startTime = routine.startTime
        draft.hasEndTime = routine.endTime != nil
        draft.endTime = routine.endTime ?? (calendar.date(bySettingHour: 9, minute: 0, second: 0, of: routine.startTime) ?? routine.startTime)
        if draft.kind == .period {
            draft.scheduleStartDate = routine.scheduleStartDate ?? Date()
            draft.scheduleEndDate = routine.scheduleEndDate ?? Date()
        }
        return draft
    }

    static func defaultExpiryAction(for kind: RoutineScheduleKind) -> RoutineExpiryAction {
        kind == .once ? .archive : .keepInList
    }

    /// 저장값이 없으면 일정 종류에 맞는 기본 요일을 돌려줍니다.
    static func activeWeekdays(for routine: Routine) -> [Int] {
        if let stored = routine.activeWeekdays {
            if routine.scheduleKind == .period, stored.isEmpty {
                return []
            }
            if !stored.isEmpty {
                return stored
            }
        }
        switch routine.scheduleKind {
        case .daily:
            return Array(1...7)
        case .weekdays:
            return [2, 3, 4, 5, 6]
        case .period:
            return []
        case .once:
            return []
        }
    }

    static func effectiveStartDay(
        for routine: Routine,
        calendar: Calendar = .current
    ) -> Date {
        if let start = routine.scheduleStartDate {
            return calendar.startOfDay(for: start)
        }
        return effectiveCreatedDay(for: routine, logs: [], calendar: calendar)
    }

    static func effectiveEndDay(
        for routine: Routine,
        calendar: Calendar = .current
    ) -> Date? {
        if let end = routine.scheduleEndDate {
            return calendar.startOfDay(for: end)
        }
        if routine.scheduleKind == .once, let once = routine.oneTimeDate {
            return calendar.startOfDay(for: once)
        }
        return nil
    }

    static func isWithinBounds(_ routine: Routine, on date: Date, calendar: Calendar = .current) -> Bool {
        let day = date.startOfDay(in: calendar)
        let start = effectiveStartDay(for: routine, calendar: calendar)
        if day < start { return false }
        if let end = effectiveEndDay(for: routine, calendar: calendar), day > end {
            return false
        }
        return true
    }

    static func isExpired(_ routine: Routine, on reference: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let end = effectiveEndDay(for: routine, calendar: calendar) else { return false }
        let today = reference.startOfDay(in: calendar)
        return today > end
    }

    static func isArchived(_ routine: Routine) -> Bool {
        routine.isArchived == true
    }

    static func isListedInActiveSection(_ routine: Routine, calendar: Calendar = .current) -> Bool {
        !isArchived(routine) && !isExpired(routine, calendar: calendar)
    }

    static func isListedInEndedSection(_ routine: Routine, calendar: Calendar = .current) -> Bool {
        !isArchived(routine) && isExpired(routine, calendar: calendar)
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
                let liveIds = Set(routines.map(\.id))
                let logs = DailyLogFetcher.fetchedLogs(liveRoutineIds: liveIds, context: context)
                routine.createdAt = effectiveCreatedDay(for: routine, logs: logs)
                changed = true
            }
            if routine.isArchived == nil {
                routine.isArchived = false
                changed = true
            }
            if routine.expiryActionRaw == nil {
                routine.expiryActionRaw = defaultExpiryAction(for: routine.scheduleKind).rawValue
                changed = true
            }
            if routine.scheduleKind == .once,
               let once = routine.oneTimeDate,
               routine.scheduleStartDate == nil {
                routine.scheduleStartDate = once
                routine.scheduleEndDate = once
                changed = true
            }
        }
        if changed {
            try? context.save()
        }
    }

    static func isActive(_ routine: Routine, on date: Date, calendar: Calendar = .current) -> Bool {
        guard isWithinBounds(routine, on: date, calendar: calendar) else { return false }
        let day = date.startOfDay(in: calendar)
        switch routine.scheduleKind {
        case .daily:
            return true
        case .weekdays:
            let weekday = calendar.component(.weekday, from: day)
            return activeWeekdays(for: routine).contains(weekday)
        case .period:
            let weekdays = activeWeekdays(for: routine)
            if weekdays.isEmpty { return true }
            let weekday = calendar.component(.weekday, from: day)
            return weekdays.contains(weekday)
        case .once:
            guard let once = routine.oneTimeDate else { return false }
            return calendar.isDate(day, inSameDayAs: calendar.startOfDay(for: once))
        }
    }

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
        if set == weekdaySet { return AppCopy.Routine.weekdayPresetWeekdays }
        if set == weekendSet { return AppCopy.Routine.weekdayPresetWeekend }
        let labels = weekdayOptions
            .filter { set.contains($0.0) }
            .map(\.1)
        return labels.isEmpty ? AppCopy.Routine.ScheduleKind.weekdays : labels.joined()
    }

    static func dateRangeSummary(
        start: Date?,
        end: Date?,
        calendar: Calendar = .current
    ) -> String? {
        guard let start, let end else { return nil }
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        if calendar.isDate(startDay, inSameDayAs: endDay) {
            df.setLocalizedDateFormatFromTemplate("MMMd")
            return df.string(from: startDay)
        }
        df.setLocalizedDateFormatFromTemplate("MMMd")
        return "\(df.string(from: startDay))~\(df.string(from: endDay))"
    }

    static func cardSubtitle(for routine: Routine, itemCount: Int, startTimeText: String) -> String {
        let cal = Calendar.current
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
            if let end = routine.scheduleEndDate {
                df.setLocalizedDateFormatFromTemplate("MMMd")
                schedulePart = "\(AppCopy.Routine.repeatsDaily) · \(AppCopy.Routine.untilDate) \(df.string(from: end))"
            } else {
                schedulePart = AppCopy.Routine.repeatsDaily
            }
        case .weekdays:
            var parts = [weekdaySummary(activeWeekdays(for: routine))]
            if let end = routine.scheduleEndDate {
                df.setLocalizedDateFormatFromTemplate("MMMd")
                parts.append("\(AppCopy.Routine.untilDate) \(df.string(from: end))")
            }
            schedulePart = parts.joined(separator: " · ")
        case .period:
            let range = dateRangeSummary(
                start: routine.scheduleStartDate,
                end: routine.scheduleEndDate,
                calendar: cal
            ) ?? AppCopy.Routine.ScheduleKind.period
            let days = activeWeekdays(for: routine)
            if days.isEmpty {
                schedulePart = "\(range) · \(AppCopy.Routine.periodEveryDay)"
            } else {
                schedulePart = "\(range) · \(weekdaySummary(days))"
            }
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

    // MARK: - 기간 프리셋

    static func thisWeekRange(calendar: Calendar = .current) -> (start: Date, end: Date) {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today.startOfDay(in: calendar))!
        let sunday = calendar.date(byAdding: .day, value: 6, to: monday)!
        return (monday, sunday)
    }

    static func nextSevenDaysRange(calendar: Calendar = .current) -> (start: Date, end: Date) {
        let start = Date().startOfDay(in: calendar)
        let end = calendar.date(byAdding: .day, value: 6, to: start)!
        return (start, end)
    }

    static func isDraftValid(_ draft: RoutineScheduleDraft) -> Bool {
        switch draft.kind {
        case .daily:
            return true
        case .weekdays:
            return !draft.activeWeekdays.isEmpty
        case .period:
            return draft.scheduleStartDate.startOfDay(in: .current)
                <= draft.scheduleEndDate.startOfDay(in: .current)
        case .once:
            return true
        }
    }
}

extension Routine {
    var scheduleKind: RoutineScheduleKind {
        get {
            RoutineScheduleKind(rawValue: scheduleKindRaw ?? RoutineScheduleKind.daily.rawValue) ?? .daily
        }
        set { scheduleKindRaw = newValue.rawValue }
    }

    var expiryAction: RoutineExpiryAction {
        get {
            RoutineExpiryAction(rawValue: expiryActionRaw ?? "") ?? RoutineSchedule.defaultExpiryAction(for: scheduleKind)
        }
        set { expiryActionRaw = newValue.rawValue }
    }
}
