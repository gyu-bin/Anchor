//
//  NotificationPreferences.swift
//  Anchor
//

import Foundation

enum NotificationPreferences {
    private enum Key {
        static let enabled = "notifications.enabled"
        static let routineStart = "notifications.routineStart"
        static let reminder = "notifications.reminder"
        static let weeklySummary = "notifications.weeklySummary"
        static let reminderOffsetMinutes = "notifications.reminderOffsetMinutes"
    }

    /// 리마인더: 루틴 시작 후 몇 분 뒤 (15 / 30 / 60)
    static var reminderOffsetMinutes: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: Key.reminderOffsetMinutes)
            if stored == 0 {
                if UserDefaults.standard.object(forKey: Key.reminderOffsetMinutes) == nil {
                    return 30
                }
            }
            return [15, 30, 60].contains(stored) ? stored : 30
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.reminderOffsetMinutes) }
    }

    static let reminderOffsetChoices: [(minutes: Int, label: String)] = [
        (15, "15분 후"),
        (30, "30분 후"),
        (60, "1시간 후"),
    ]

    static var notificationsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: Key.enabled) == nil { return true }
            return UserDefaults.standard.bool(forKey: Key.enabled)
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.enabled) }
    }

    static var routineStartEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: Key.routineStart) == nil { return true }
            return UserDefaults.standard.bool(forKey: Key.routineStart)
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.routineStart) }
    }

    static var reminderEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: Key.reminder) == nil { return true }
            return UserDefaults.standard.bool(forKey: Key.reminder)
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.reminder) }
    }

    static var weeklySummaryEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: Key.weeklySummary) == nil { return true }
            return UserDefaults.standard.bool(forKey: Key.weeklySummary)
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.weeklySummary) }
    }
}
