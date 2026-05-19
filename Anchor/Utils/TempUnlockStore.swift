//
//  TempUnlockStore.swift
//  Anchor
//

import Foundation

/// 10분 임시 잠금 해제 상태를 App Group UserDefaults에 저장합니다.
/// ShieldManager.refresh가 호출될 때 이 상태를 확인해 잠금 적용 여부를 결정합니다.
enum TempUnlockStore {
    private static let defaults = UserDefaults(suiteName: "group.com.rbqls6651.anchor")
    private static let key = "tempUnlock.expiresAt"

    static var expiresAt: Date? {
        get { defaults?.object(forKey: key) as? Date }
        set {
            if let v = newValue { defaults?.set(v, forKey: key) }
            else { defaults?.removeObject(forKey: key) }
        }
    }

    static var isActive: Bool {
        guard let exp = expiresAt else { return false }
        return exp > Date()
    }

    static var remainingSeconds: Int {
        guard let exp = expiresAt else { return 0 }
        return max(0, Int(exp.timeIntervalSinceNow))
    }

    static func activate(minutes: Int = 10) {
        expiresAt = Date().addingTimeInterval(TimeInterval(minutes * 60))
    }

    static func deactivate() {
        expiresAt = nil
    }
}
