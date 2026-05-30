//
//  PremiumTrialStore.swift
//  Anchor
//

import Foundation

/// 첫 실행부터 N일간 전체 기능 체험. 기간이 지나면 무료 한도 + Paywall.
enum PremiumTrialStore {
    static let trialDurationDays = 14

    private static let trialStartKey = "premium.trialStart"
    private static let expiredPaywallShownKey = "premium.trialExpiredPaywallShown"

    private static var suite: UserDefaults? {
        UserDefaults(suiteName: SharedShieldStore.appGroupID) ?? UserDefaults.standard
    }

    /// 최초 실행 시 체험 시작일을 기록합니다.
    static func ensureStarted() {
        guard suite?.object(forKey: trialStartKey) == nil else { return }
        suite?.set(Date(), forKey: trialStartKey)
    }

    static var trialStartDate: Date? {
        suite?.object(forKey: trialStartKey) as? Date
    }

    /// 평생 구매 전, 체험 기간 안이면 true.
    static var isTrialActive: Bool {
        guard !PremiumStorage.isPurchased else { return false }
        guard let start = trialStartDate,
              let end = Calendar.current.date(
                  byAdding: .day,
                  value: trialDurationDays,
                  to: start
              ) else { return false }
        return Date() < end
    }

    static var trialEndDate: Date? {
        guard let start = trialStartDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: trialDurationDays, to: start)
    }

    /// 체험 종료까지 남은 일수(당일 포함, 최소 0).
    static var trialDaysRemaining: Int {
        guard isTrialActive, let end = trialEndDate else { return 0 }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let endDay = cal.startOfDay(for: end)
        let days = cal.dateComponents([.day], from: today, to: endDay).day ?? 0
        return max(0, days)
    }

    /// 체험을 시작했고 기간이 끝났으며 아직 구매하지 않음.
    static var hasTrialExpired: Bool {
        guard trialStartDate != nil else { return false }
        return !isTrialActive && !PremiumStorage.isPurchased
    }

    /// 체험 종료 후 Paywall을 아직 한 번도 띄우지 않았으면 true (이후 false).
    static func consumeExpiredPaywallPrompt() -> Bool {
        guard hasTrialExpired else { return false }
        guard suite?.bool(forKey: expiredPaywallShownKey) != true else { return false }
        suite?.set(true, forKey: expiredPaywallShownKey)
        return true
    }
}
