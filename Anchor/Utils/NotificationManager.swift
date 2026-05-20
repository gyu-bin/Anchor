//
//  NotificationManager.swift
//  Anchor
//

import Foundation
import SwiftData
import UserNotifications

enum NotificationManager {
    private static let routineCategoryId = "ROUTINE_START"
    private static let reminderCategoryId = "ROUTINE_REMINDER"
    private static let deadlineCategoryId = "ROUTINE_DEADLINE"
    private static let weeklyCategoryId = "WEEKLY_SUMMARY"
    private static let incompleteDayCategoryId = "INCOMPLETE_DAY_NUDGE"
    private static let dayCelebrationCategoryId = "DAY_CELEBRATION"
    private static let incompleteTodayId = "end-of-day-incomplete-today"
    private static let celebrationTodayId = "end-of-day-celebration-today"

    static func registerCategories() {
        let openToday = UNNotificationAction(
            identifier: "OPEN_TODAY",
            title: AppCopy.Notification.openToday,
            options: [.foreground]
        )
        let categories = [
            UNNotificationCategory(
                identifier: routineCategoryId,
                actions: [openToday],
                intentIdentifiers: [],
                options: []
            ),
            UNNotificationCategory(
                identifier: reminderCategoryId,
                actions: [openToday],
                intentIdentifiers: [],
                options: []
            ),
            UNNotificationCategory(
                identifier: deadlineCategoryId,
                actions: [openToday],
                intentIdentifiers: [],
                options: []
            ),
            UNNotificationCategory(
                identifier: weeklyCategoryId,
                actions: [openToday],
                intentIdentifiers: [],
                options: []
            ),
            UNNotificationCategory(
                identifier: incompleteDayCategoryId,
                actions: [openToday],
                intentIdentifiers: [],
                options: []
            ),
            UNNotificationCategory(
                identifier: dayCelebrationCategoryId,
                actions: [],
                intentIdentifiers: [],
                options: []
            ),
        ]
        UNUserNotificationCenter.current().setNotificationCategories(Set(categories))
    }

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func rescheduleAll(modelContext: ModelContext) throws {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        guard NotificationPreferences.notificationsEnabled else { return }

        let fd = FetchDescriptor<Routine>()
        let routines = try modelContext.fetch(fd)

        if NotificationPreferences.notificationsEnabled {
            for routine in routines {
                scheduleRoutineNotifications(for: routine)
            }
        }

        refreshDailyClosureNotifications(modelContext: modelContext)

        if NotificationPreferences.weeklySummaryEnabled, PremiumStorage.isPremium {
            scheduleWeeklySummary()
        }
    }

    static func scheduleRoutineNotifications(for routine: Routine) {
        guard !routine.items.isEmpty else { return }
        guard !RestDayStore.isRestToday() else { return }
        guard !RoutineSchedule.isArchived(routine) else { return }
        guard !RoutineSchedule.isExpired(routine) else { return }

        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: routine.startTime)
        guard let hour = comps.hour, let minute = comps.minute else { return }

        switch routine.scheduleKind {
        case .daily:
            scheduleDailyPair(
                routine: routine,
                hour: hour,
                minute: minute,
                calendar: cal
            )
        case .weekdays:
            let weekdays = RoutineSchedule.activeWeekdays(for: routine)
            for weekday in weekdays {
                scheduleWeekdayPair(
                    routine: routine,
                    weekday: weekday,
                    hour: hour,
                    minute: minute,
                    calendar: cal
                )
            }
        case .once:
            guard let once = routine.oneTimeDate else { return }
            let dayStart = cal.startOfDay(for: once)
            guard dayStart >= cal.startOfDay(for: Date()) else { return }
            scheduleOncePair(
                routine: routine,
                day: dayStart,
                hour: hour,
                minute: minute,
                calendar: cal
            )
        case .period:
            let weekdays = RoutineSchedule.activeWeekdays(for: routine)
            if weekdays.isEmpty {
                scheduleDailyPair(
                    routine: routine,
                    hour: hour,
                    minute: minute,
                    calendar: cal
                )
            } else {
                for weekday in weekdays {
                    scheduleWeekdayPair(
                        routine: routine,
                        weekday: weekday,
                        hour: hour,
                        minute: minute,
                        calendar: cal
                    )
                }
            }
        }
    }

    private static func scheduleDailyPair(
        routine: Routine,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) {
        var startComps = DateComponents()
        startComps.hour = hour
        startComps.minute = minute
        addNotifications(
            routine: routine,
            startComponents: startComps,
            repeats: true,
            idSuffix: "daily",
            calendar: calendar
        )
    }

    private static func scheduleWeekdayPair(
        routine: Routine,
        weekday: Int,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) {
        var startComps = DateComponents()
        startComps.weekday = weekday
        startComps.hour = hour
        startComps.minute = minute
        addNotifications(
            routine: routine,
            startComponents: startComps,
            repeats: true,
            idSuffix: "w\(weekday)",
            calendar: calendar
        )
    }

    private static func scheduleOncePair(
        routine: Routine,
        day: Date,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) {
        var startComps = calendar.dateComponents([.year, .month, .day], from: day)
        startComps.hour = hour
        startComps.minute = minute
        addNotifications(
            routine: routine,
            startComponents: startComps,
            repeats: false,
            idSuffix: "once",
            calendar: calendar
        )
    }

    private static func addNotifications(
        routine: Routine,
        startComponents: DateComponents,
        repeats: Bool,
        idSuffix: String,
        calendar: Calendar
    ) {
        if NotificationPreferences.routineStartEnabled {
            let startTrigger = UNCalendarNotificationTrigger(dateMatching: startComponents, repeats: repeats)
            let startContent = UNMutableNotificationContent()
            let start = AppCopy.Notification.routineStart(name: routine.name)
            startContent.title = start.title
            startContent.body = start.body
            startContent.sound = .default
            startContent.categoryIdentifier = routineCategoryId
            startContent.userInfo = ["openToday": true, "refreshShield": true]

            let startReq = UNNotificationRequest(
                identifier: "routine-start-\(routine.id.uuidString)-\(idSuffix)",
                content: startContent,
                trigger: startTrigger
            )
            UNUserNotificationCenter.current().add(startReq)
        }

        if NotificationPreferences.reminderEnabled {
            let offset = NotificationPreferences.reminderOffsetMinutes
            let anchor = calendar.date(from: startComponents)
                ?? calendar.date(bySettingHour: startComponents.hour ?? 0, minute: startComponents.minute ?? 0, second: 0, of: Date())
                ?? routine.startTime
            let reminderDate = calendar.date(byAdding: .minute, value: offset, to: anchor) ?? anchor
            var reminderComps = startComponents
            reminderComps.hour = calendar.component(.hour, from: reminderDate)
            reminderComps.minute = calendar.component(.minute, from: reminderDate)

            let reminderTrigger = UNCalendarNotificationTrigger(dateMatching: reminderComps, repeats: repeats)
            let reminderContent = UNMutableNotificationContent()
            let reminder = AppCopy.Notification.reminder(name: routine.name)
            reminderContent.title = reminder.title
            reminderContent.body = reminder.body
            reminderContent.sound = .default
            reminderContent.categoryIdentifier = reminderCategoryId
            reminderContent.userInfo = [
                "openToday": true,
                "routineId": routine.id.uuidString,
                "isReminder": true,
            ]

            let reminderReq = UNNotificationRequest(
                identifier: "routine-reminder-\(routine.id.uuidString)-\(idSuffix)",
                content: reminderContent,
                trigger: reminderTrigger
            )
            UNUserNotificationCenter.current().add(reminderReq)
        }

        if routine.endTime != nil, NotificationPreferences.notificationsEnabled {
            addDeadlineNotification(
                routine: routine,
                startComponents: startComponents,
                repeats: repeats,
                idSuffix: idSuffix,
                calendar: calendar
            )
        }
    }

    private static func addDeadlineNotification(
        routine: Routine,
        startComponents: DateComponents,
        repeats: Bool,
        idSuffix: String,
        calendar: Calendar
    ) {
        guard let endTime = routine.endTime else { return }
        let endComps = calendar.dateComponents([.hour, .minute], from: endTime)
        var merged = startComponents
        merged.hour = endComps.hour
        merged.minute = endComps.minute
        guard let endDate = calendar.date(from: merged),
              let notifyDate = calendar.date(byAdding: .minute, value: -30, to: endDate) else { return }

        var triggerComps = startComponents
        triggerComps.hour = calendar.component(.hour, from: notifyDate)
        triggerComps.minute = calendar.component(.minute, from: notifyDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: repeats)
        let content = UNMutableNotificationContent()
        let copy = AppCopy.Notification.deadlineReminder(name: routine.name)
        content.title = copy.title
        content.body = copy.body
        content.sound = .default
        content.categoryIdentifier = deadlineCategoryId
        content.userInfo = [
            "openToday": true,
            "routineId": routine.id.uuidString,
            "isDeadlineReminder": true,
        ]

        let request = UNNotificationRequest(
            identifier: "routine-deadline-\(routine.id.uuidString)-\(idSuffix)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// 오늘 해당 루틴을 이미 완료했으면 리마인더를 보내지 않습니다.
    static func shouldDeliverReminder(
        routineId: UUID,
        modelContext: ModelContext
    ) -> Bool {
        guard let routines = try? modelContext.fetch(FetchDescriptor<Routine>()),
              let routine = routines.first(where: { $0.id == routineId }) else {
            return true
        }
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: Date())
        guard RoutineSchedule.isActive(routine, on: Date(), calendar: calendar) else { return false }
        let complete = (try? routineIsFullyCompleteToday(
            routine,
            dayStart: dayStart,
            calendar: calendar,
            modelContext: modelContext
        )) ?? false
        return !complete
    }

    /// 오늘 마감 연장 후, 연장된 시각 기준 30분 전 일회 알림을 다시 잡습니다.
    static func refreshTodayDeadlineReminderAfterExtension(for routine: Routine) {
        guard NotificationPreferences.notificationsEnabled else { return }
        guard routine.endTime != nil else { return }

        let calendar = Calendar.current
        let dayKey = RoutineDeadlineExtensionStore.dayKey(for: Date(), calendar: calendar)
        let identifier = "routine-deadline-ext-\(routine.id.uuidString)-\(dayKey)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        guard let end = RoutineDeadline.endTimeToday(for: routine),
              let notifyDate = calendar.date(byAdding: .minute, value: -30, to: end),
              notifyDate > Date() else { return }

        let content = UNMutableNotificationContent()
        let copy = AppCopy.Notification.deadlineReminder(name: routine.name)
        content.title = copy.title
        content.body = copy.body
        content.sound = .default
        content.categoryIdentifier = deadlineCategoryId
        content.userInfo = [
            "openToday": true,
            "routineId": routine.id.uuidString,
            "isDeadlineReminder": true,
        ]

        let interval = max(1, notifyDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelReminders(for routine: Routine) {
        let prefixes = [
            "routine-reminder-\(routine.id.uuidString)-",
            "routine-deadline-\(routine.id.uuidString)-",
            "routine-deadline-ext-\(routine.id.uuidString)-",
        ]
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.filter { req in
                prefixes.contains { req.identifier.hasPrefix($0) }
            }.map(\.identifier)
            guard !ids.isEmpty else { return }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private static func routineIsFullyCompleteToday(
        _ routine: Routine,
        dayStart: Date,
        calendar: Calendar,
        modelContext: ModelContext
    ) throws -> Bool {
        if RestDayStore.isRestDay(dayStart, calendar: calendar) {
            return true
        }
        let rid = routine.id
        var fd = FetchDescriptor<DailyLog>(
            predicate: #Predicate { log in
                log.routineId == rid
            }
        )
        fd.fetchLimit = 200
        let logs = try modelContext.fetch(fd)
        guard let log = logs.first(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) else {
            return false
        }
        return log.isFullyCompleted
    }

    /// 매주 일요일 오전 9시 주간 요약
    static func scheduleWeeklySummary() {
        var comps = DateComponents()
        comps.weekday = 1
        comps.hour = 9
        comps.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = AppCopy.Notification.weeklyTitle
        content.body = AppCopy.Notification.weeklyBodyPlaceholder
        content.sound = .default
        content.categoryIdentifier = weeklyCategoryId
        content.userInfo = ["openHistory": true]

        let request = UNNotificationRequest(
            identifier: "weekly-summary",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// 앱 실행 시 이번 주 완료 일수로 주간 알림 문구 갱신
    static func updateWeeklySummaryContent(fullDays: Int) {
        guard NotificationPreferences.weeklySummaryEnabled, PremiumStorage.isPremium else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly-summary"])

        var comps = DateComponents()
        comps.weekday = 1
        comps.hour = 9
        comps.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = AppCopy.Notification.weeklyTitle
        content.body = AppCopy.Notification.weeklyBody(days: fullDays)
        content.sound = .default
        content.categoryIdentifier = weeklyCategoryId
        content.userInfo = ["openHistory": true]

        let request = UNNotificationRequest(
            identifier: "weekly-summary",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Daily closure (저녁·밤 알림)

extension NotificationManager {
    /// 오늘 기준: 미완료면 저녁 알림, 전부 완료면 밤 격려 알림 예약
    static func refreshDailyClosureNotifications(modelContext: ModelContext) {
        guard NotificationPreferences.notificationsEnabled else {
            cancelDailyClosureNotifications()
            return
        }

        cancelDailyClosureNotifications()

        let calendar = Calendar.current
        let now = Date()

        guard !RestDayStore.isRestToday(calendar: calendar) else { return }

        do {
            let routines = try actionableRoutinesToday(modelContext: modelContext, calendar: calendar)
            guard !routines.isEmpty else { return }

            let allComplete = try isAllRoutinesCompleteToday(
                routines: routines,
                modelContext: modelContext,
                calendar: calendar
            )

            if allComplete {
                scheduleCelebrationForTodayIfNeeded(now: now, calendar: calendar)
            } else {
                scheduleIncompleteNudgeForTodayIfNeeded(now: now, calendar: calendar)
            }
        } catch {
            return
        }
    }

    static func shouldDeliverIncompleteDayNudge(modelContext: ModelContext) -> Bool {
        let calendar = Calendar.current
        if RestDayStore.isRestToday(calendar: calendar) { return false }
        guard let routines = try? actionableRoutinesToday(modelContext: modelContext, calendar: calendar),
              !routines.isEmpty else { return false }
        let complete = (try? isAllRoutinesCompleteToday(
            routines: routines,
            modelContext: modelContext,
            calendar: calendar
        )) ?? false
        return !complete
    }

    static func shouldDeliverDayCelebration(modelContext: ModelContext) -> Bool {
        let calendar = Calendar.current
        if RestDayStore.isRestToday(calendar: calendar) { return false }
        guard let routines = try? actionableRoutinesToday(modelContext: modelContext, calendar: calendar),
              !routines.isEmpty else { return false }
        return (try? isAllRoutinesCompleteToday(
            routines: routines,
            modelContext: modelContext,
            calendar: calendar
        )) ?? false
    }

    private static func cancelDailyClosureNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [incompleteTodayId, celebrationTodayId]
        )
    }

    private static func scheduleIncompleteNudgeForTodayIfNeeded(now: Date, calendar: Calendar) {
        guard let fireDate = todayAt(
            hour: NotificationPreferences.incompleteDayNudgeHour,
            minute: NotificationPreferences.incompleteDayNudgeMinute,
            calendar: calendar
        ), fireDate > now else { return }

        let content = UNMutableNotificationContent()
        content.title = AppCopy.Notification.incompleteDayTitle
        content.body = AppCopy.Notification.incompleteDayBody
        content.sound = .default
        content.categoryIdentifier = incompleteDayCategoryId
        content.userInfo = ["openToday": true, "isIncompleteDayNudge": true]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: fireDate.timeIntervalSince(now),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: incompleteTodayId,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private static func scheduleCelebrationForTodayIfNeeded(now: Date, calendar: Calendar) {
        guard let fireDate = todayAt(
            hour: NotificationPreferences.dayCelebrationHour,
            minute: NotificationPreferences.dayCelebrationMinute,
            calendar: calendar
        ), fireDate > now else { return }

        let content = UNMutableNotificationContent()
        content.title = AppCopy.Notification.dayCelebrationTitle
        content.body = AppCopy.Notification.dayCelebrationBody
        content.sound = .default
        content.categoryIdentifier = dayCelebrationCategoryId
        content.userInfo = ["isDayCelebration": true]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: fireDate.timeIntervalSince(now),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: celebrationTodayId,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private static func todayAt(hour: Int, minute: Int, calendar: Calendar) -> Date? {
        var comps = calendar.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return calendar.date(from: comps)
    }

    private static func actionableRoutinesToday(
        modelContext: ModelContext,
        calendar: Calendar
    ) throws -> [Routine] {
        let all = try modelContext.fetch(FetchDescriptor<Routine>())
        return all.filter {
            !$0.items.isEmpty && RoutineSchedule.isActive($0, on: Date(), calendar: calendar)
        }
    }

    private static func isAllRoutinesCompleteToday(
        routines: [Routine],
        modelContext: ModelContext,
        calendar: Calendar
    ) throws -> Bool {
        let dayStart = calendar.startOfDay(for: Date())
        for routine in routines {
            let rid = routine.id
            var fd = FetchDescriptor<DailyLog>(
                predicate: #Predicate { log in
                    log.routineId == rid
                }
            )
            fd.fetchLimit = 200
            let logs = try modelContext.fetch(fd)
            guard let log = logs.first(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }),
                  log.isFullyCompleted else {
                return false
            }
        }
        return true
    }
}
