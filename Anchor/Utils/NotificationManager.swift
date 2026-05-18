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

    static func registerCategories() {
        let openToday = UNNotificationAction(
            identifier: "OPEN_TODAY",
            title: "오늘 보기",
            options: [.foreground]
        )
        let routineCategory = UNNotificationCategory(
            identifier: routineCategoryId,
            actions: [openToday],
            intentIdentifiers: [],
            options: []
        )
        let reminderCategory = UNNotificationCategory(
            identifier: reminderCategoryId,
            actions: [openToday],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([routineCategory, reminderCategory])
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

        let fd = FetchDescriptor<Routine>()
        let routines = try modelContext.fetch(fd)

        for routine in routines {
            scheduleRoutineNotifications(for: routine)
        }
    }

    static func scheduleRoutineNotifications(for routine: Routine) {
        guard !routine.items.isEmpty else { return }

        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: routine.startTime)
        guard let hour = comps.hour, let minute = comps.minute else { return }

        var startComps = DateComponents()
        startComps.hour = hour
        startComps.minute = minute

        let startTrigger = UNCalendarNotificationTrigger(dateMatching: startComps, repeats: true)
        let startContent = UNMutableNotificationContent()
        startContent.title = "⚓ \(routine.name)을(를) 시작할 시간이에요"
        startContent.body = "오늘도 루틴을 완료하고 잠금을 해제해보세요"
        startContent.sound = .default
        startContent.categoryIdentifier = routineCategoryId
        startContent.userInfo = ["openToday": true]

        let startReq = UNNotificationRequest(
            identifier: "routine-start-\(routine.id.uuidString)",
            content: startContent,
            trigger: startTrigger
        )
        UNUserNotificationCenter.current().add(startReq)

        let anchor = cal.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? routine.startTime
        let reminderDate = cal.date(byAdding: .minute, value: 30, to: anchor) ?? anchor
        var reminderComps = DateComponents()
        reminderComps.hour = cal.component(.hour, from: reminderDate)
        reminderComps.minute = cal.component(.minute, from: reminderDate)

        let reminderTrigger = UNCalendarNotificationTrigger(dateMatching: reminderComps, repeats: true)
        let reminderContent = UNMutableNotificationContent()
        reminderContent.title = "아직 루틴이 남아있어요"
        reminderContent.body = "\(routine.name)을(를) 마저 완료해볼까요?"
        reminderContent.sound = .default
        reminderContent.categoryIdentifier = reminderCategoryId
        reminderContent.userInfo = ["openToday": true]

        let reminderReq = UNNotificationRequest(
            identifier: "routine-reminder-\(routine.id.uuidString)",
            content: reminderContent,
            trigger: reminderTrigger
        )
        UNUserNotificationCenter.current().add(reminderReq)
    }
}
