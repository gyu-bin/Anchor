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
    }

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
