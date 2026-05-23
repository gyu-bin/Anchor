//
//  NotificationManager.swift
//  Anchor
//

import Foundation
import SwiftData
import UserNotifications

enum NotificationManager {
    private static let routineCategoryId = "ROUTINE_START"
    private static let deadlineCategoryId = "ROUTINE_DEADLINE"
    private static let weeklyCategoryId = "WEEKLY_SUMMARY"

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

        for routine in routines {
            scheduleRoutineNotifications(for: routine)
        }

        if NotificationPreferences.weeklySummaryEnabled, PremiumStorage.isPremium {
            scheduleWeeklySummary()
        }

        // rescheduleAll이 루틴 완료 직후 호출될 때 마감·미완료 알림이 재등록되는 문제 방지
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: Date())
        for routine in routines where !routine.items.isEmpty {
            guard let isComplete = try? routineIsFullyCompleteToday(
                routine, dayStart: dayStart, calendar: calendar, modelContext: modelContext
            ), isComplete else { continue }
            removePendingDeadlineNotifications(for: routine)
        }
    }

    private static func removePendingDeadlineNotifications(for routine: Routine) {
        let idBase = routine.id.uuidString
        var ids: [String] = []
        switch routine.scheduleKind {
        case .daily:
            ids.append("routine-deadline-\(idBase)-daily")
            ids.append("routine-incomplete-\(idBase)-daily")
        case .weekdays:
            for weekday in RoutineSchedule.activeWeekdays(for: routine) {
                ids.append("routine-deadline-\(idBase)-w\(weekday)")
                ids.append("routine-incomplete-\(idBase)-w\(weekday)")
            }
        case .period:
            let weekdays = RoutineSchedule.activeWeekdays(for: routine)
            if weekdays.isEmpty {
                ids.append("routine-deadline-\(idBase)-daily")
                ids.append("routine-incomplete-\(idBase)-daily")
            } else {
                for weekday in weekdays {
                    ids.append("routine-deadline-\(idBase)-w\(weekday)")
                    ids.append("routine-incomplete-\(idBase)-w\(weekday)")
                }
            }
        case .once:
            ids.append("routine-deadline-\(idBase)-once")
            ids.append("routine-incomplete-\(idBase)-once")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
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

        if routine.endTime != nil, NotificationPreferences.notificationsEnabled {
            addDeadlineNotifications(
                routine: routine,
                startComponents: startComponents,
                repeats: repeats,
                idSuffix: idSuffix,
                calendar: calendar
            )
        }
    }

    private static func addDeadlineNotifications(
        routine: Routine,
        startComponents: DateComponents,
        repeats: Bool,
        idSuffix: String,
        calendar: Calendar
    ) {
        guard let endTime = routine.endTime else { return }
        let endComps = calendar.dateComponents([.hour, .minute], from: endTime)
        var endTriggerComps = startComponents
        endTriggerComps.hour = endComps.hour
        endTriggerComps.minute = endComps.minute

        // 종료 30분 전 알림
        if let endDate = calendar.date(from: endTriggerComps),
           let notifyDate = calendar.date(byAdding: .minute, value: -30, to: endDate) {
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

        // 종료 시간 정각 미완료 알림
        let endTrigger = UNCalendarNotificationTrigger(dateMatching: endTriggerComps, repeats: repeats)
        let incompleteContent = UNMutableNotificationContent()
        let incomplete = AppCopy.Notification.routineIncomplete(name: routine.name)
        incompleteContent.title = incomplete.title
        incompleteContent.body = incomplete.body
        incompleteContent.sound = .default
        incompleteContent.categoryIdentifier = deadlineCategoryId
        incompleteContent.userInfo = [
            "openToday": true,
            "routineId": routine.id.uuidString,
            "isDeadlineReminder": true,
        ]

        let incompleteReq = UNNotificationRequest(
            identifier: "routine-incomplete-\(routine.id.uuidString)-\(idSuffix)",
            content: incompleteContent,
            trigger: endTrigger
        )
        UNUserNotificationCenter.current().add(incompleteReq)
    }

    /// 오늘 해당 루틴을 이미 완료했으면 알림을 보내지 않습니다.
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

    /// 오늘 마감 연장 후, 연장된 시각 기준 30분 전과 종료 시각 일회 알림을 다시 잡습니다.
    static func refreshTodayDeadlineReminderAfterExtension(for routine: Routine) {
        guard NotificationPreferences.notificationsEnabled else { return }
        guard routine.endTime != nil else { return }

        let calendar = Calendar.current
        let dayKey = RoutineDeadlineExtensionStore.dayKey(for: Date(), calendar: calendar)
        let deadlineId = "routine-deadline-ext-\(routine.id.uuidString)-\(dayKey)"
        let incompleteId = "routine-incomplete-ext-\(routine.id.uuidString)-\(dayKey)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [deadlineId, incompleteId])

        guard let end = RoutineDeadline.endTimeToday(for: routine),
              end > Date() else { return }

        // 종료 30분 전 알림
        if let notifyDate = calendar.date(byAdding: .minute, value: -30, to: end),
           notifyDate > Date() {
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
            let request = UNNotificationRequest(identifier: deadlineId, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }

        // 종료 시간 정각 미완료 알림
        let incompleteContent = UNMutableNotificationContent()
        let incomplete = AppCopy.Notification.routineIncomplete(name: routine.name)
        incompleteContent.title = incomplete.title
        incompleteContent.body = incomplete.body
        incompleteContent.sound = .default
        incompleteContent.categoryIdentifier = deadlineCategoryId
        incompleteContent.userInfo = [
            "openToday": true,
            "routineId": routine.id.uuidString,
            "isDeadlineReminder": true,
        ]
        let endInterval = max(1, end.timeIntervalSinceNow)
        let endTrigger = UNTimeIntervalNotificationTrigger(timeInterval: endInterval, repeats: false)
        let endReq = UNNotificationRequest(identifier: incompleteId, content: incompleteContent, trigger: endTrigger)
        UNUserNotificationCenter.current().add(endReq)
    }

    static func cancelReminders(for routine: Routine) {
        let prefixes = [
            "routine-deadline-\(routine.id.uuidString)-",
            "routine-deadline-ext-\(routine.id.uuidString)-",
            "routine-incomplete-\(routine.id.uuidString)-",
            "routine-incomplete-ext-\(routine.id.uuidString)-",
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
