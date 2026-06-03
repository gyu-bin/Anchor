//
//  PremiumLimits.swift
//  Anchor
//

import Foundation

/// A안 무료 한도 · 7,900원 평생 해제
enum PremiumLimits {
    static let displayPriceKRW = "₩7,900"
    static let productID = "com.rbqls6651.anchor.unlock"

    static let maxFreeRoutines = 3
    static let maxItemsPerRoutine = 5
    static let maxAppsPerRoutine = 5
    static let maxWebDomainsPerRoutine = 3
    static let maxQuickLockApps = 5

    static func allowedQuickLockAppCount(isPremium: Bool) -> Int {
        isPremium ? Int.max : maxQuickLockApps
    }

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

    /// 무료 기록 조회 시작일 — 이번 달 1일 0시
    static func currentMonthStart(calendar: Calendar = .current, now: Date = Date()) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: now)
        return calendar.date(from: comps) ?? calendar.startOfDay(for: now)
    }

    static func historyCutoffDate(calendar: Calendar = .current, now: Date = Date()) -> Date {
        currentMonthStart(calendar: calendar, now: now)
    }

    static func includesHistoryDate(
        _ date: Date,
        isPremium: Bool,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> Bool {
        if isPremium { return true }
        return calendar.startOfDay(for: date) >= historyCutoffDate(calendar: calendar, now: now)
    }

    /// 달력에서 보여 주는 달이 무료 범위인지 (이번 달만)
    static func includesHistoryMonth(
        _ monthStart: Date,
        isPremium: Bool,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> Bool {
        if isPremium { return true }
        let shown = calendar.dateComponents([.year, .month], from: monthStart)
        let current = calendar.dateComponents([.year, .month], from: now)
        return shown.year == current.year && shown.month == current.month
    }
}

enum PremiumStorage {
    static let unlockedKey = "premium.isUnlocked"

    /// StoreKit 평생 구매 여부 (체험 기간과 무관).
    static var isPurchased: Bool {
        if UserDefaults.standard.bool(forKey: unlockedKey) { return true }
        return UserDefaults(suiteName: SharedShieldStore.appGroupID)?.bool(forKey: unlockedKey) == true
    }

    static func setPurchased(_ unlocked: Bool) {
        UserDefaults.standard.set(unlocked, forKey: unlockedKey)
        UserDefaults(suiteName: SharedShieldStore.appGroupID)?.set(unlocked, forKey: unlockedKey)
    }
}

/// Paywall·한도 판단에 쓰는 접근 권한 (평생 구매).
enum PremiumAccess {
    static var hasFullAccess: Bool {
        PremiumStorage.isPurchased
    }
}
