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
                identifier: reminderCategoryId,
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

        if NotificationPreferences.routineStartEnabled || NotificationPreferences.reminderEnabled {
            for routine in routines {
                scheduleRoutineNotifications(for: routine)
            }
        }

        if NotificationPreferences.weeklySummaryEnabled, PremiumStorage.isPremium {
            scheduleWeeklySummary()
        }
    }

    static func scheduleRoutineNotifications(for routine: Routine) {
        guard !routine.items.isEmpty else { return }
        guard !RestDayStore.isRestToday() else { return }

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
            startContent.userInfo = ["openToday": true]

            let startReq = UNNotificationRequest(
                identifier: "routine-start-\(routine.id.uuidString)-\(idSuffix)",
                content: startContent,
                trigger: startTrigger
            )
            UNUserNotificationCenter.current().add(startReq)
        }

        if NotificationPreferences.reminderEnabled {
            let anchor = calendar.date(from: startComponents)
                ?? calendar.date(bySettingHour: startComponents.hour ?? 0, minute: startComponents.minute ?? 0, second: 0, of: Date())
                ?? routine.startTime
            let reminderDate = calendar.date(byAdding: .minute, value: 30, to: anchor) ?? anchor
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
            reminderContent.userInfo = ["openToday": true]

            let reminderReq = UNNotificationRequest(
                identifier: "routine-reminder-\(routine.id.uuidString)-\(idSuffix)",
                content: reminderContent,
                trigger: reminderTrigger
            )
            UNUserNotificationCenter.current().add(reminderReq)
        }
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
