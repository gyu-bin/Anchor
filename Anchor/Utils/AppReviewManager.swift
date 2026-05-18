//
//  AppReviewManager.swift
//  Anchor
//

import StoreKit
import UIKit

enum AppReviewManager {
    private static let fullCompletionsKey = "review.fullRoutineCompletions"
    private static let lastRequestKey = "review.lastRequestDate"

    /// 루틴 하나를 오늘 전부 완료했을 때 호출
    static func recordRoutineFullyCompleted() {
        let count = UserDefaults.standard.integer(forKey: fullCompletionsKey) + 1
        UserDefaults.standard.set(count, forKey: fullCompletionsKey)
        if count == 1 || count == 3 {
            requestReviewIfAppropriate()
        }
    }

    private static func requestReviewIfAppropriate() {
        let now = Date()
        if let last = UserDefaults.standard.object(forKey: lastRequestKey) as? Date,
           now.timeIntervalSince(last) < 60 * 60 * 24 * 120 {
            return
        }
        UserDefaults.standard.set(now, forKey: lastRequestKey)
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}
