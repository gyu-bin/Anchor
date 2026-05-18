//
//  PremiumLimits.swift
//  Anchor
//

import Foundation

/// A안 무료 한도 · 1,900원 평생 해제
enum PremiumLimits {
    static let displayPriceKRW = "₩1,900"
    static let productID = "com.rbqls6651.anchor.unlock"

    static let maxFreeRoutines = 3
    static let maxItemsPerRoutine = 5
    static let maxAppsPerRoutine = 8
    static let maxWebDomainsPerRoutine = 3
    static let freeHistoryDays = 30

    static func canAddRoutine(currentCount: Int, isPremium: Bool) -> Bool {
        isPremium || currentCount < maxFreeRoutines
    }

    static func canAddItem(currentCount: Int, isPremium: Bool) -> Bool {
        isPremium || currentCount < maxItemsPerRoutine
    }

    static func allowedAppCount(isPremium: Bool) -> Int {
        isPremium ? Int.max : maxAppsPerRoutine
    }

    static func canAddWebDomain(currentCount: Int, isPremium: Bool) -> Bool {
        isPremium || currentCount < maxWebDomainsPerRoutine
    }

    static func historyCutoffDate(calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: -freeHistoryDays, to: today) ?? today
    }

    static func includesHistoryDate(_ date: Date, isPremium: Bool, calendar: Calendar = .current) -> Bool {
        if isPremium { return true }
        return calendar.startOfDay(for: date) >= historyCutoffDate(calendar: calendar)
    }
}

enum PremiumStorage {
    static let unlockedKey = "premium.isUnlocked"

    static var isPremium: Bool {
        if UserDefaults.standard.bool(forKey: unlockedKey) { return true }
        return UserDefaults(suiteName: SharedShieldStore.appGroupID)?.bool(forKey: unlockedKey) == true
    }

    static func setPremium(_ unlocked: Bool) {
        UserDefaults.standard.set(unlocked, forKey: unlockedKey)
        UserDefaults(suiteName: SharedShieldStore.appGroupID)?.set(unlocked, forKey: unlockedKey)
    }
}
