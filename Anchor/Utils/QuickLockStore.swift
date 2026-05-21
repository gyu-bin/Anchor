
//
//  QuickLockStore.swift
//  Anchor
//

import Foundation

enum QuickLockStore {
    private static let defaults = UserDefaults(suiteName: SharedShieldStore.appGroupID)
    private static let expiresAtKey = "quickLock.expiresAt"
    private static let selectionDataKey = "quickLock.selectionData"

    static var expiresAt: Date? {
        get { defaults?.object(forKey: expiresAtKey) as? Date }
        set { defaults?.set(newValue, forKey: expiresAtKey) }
    }

    static var isActive: Bool {
        guard let exp = expiresAt else { return false }
        return exp > Date()
    }

    static var remainingSeconds: Int {
        guard let exp = expiresAt else { return 0 }
        return max(0, Int(exp.timeIntervalSinceNow))
    }

    static var selectionData: Data? {
        get { defaults?.data(forKey: selectionDataKey) }
        set { defaults?.set(newValue, forKey: selectionDataKey) }
    }

    static func activate(minutes: Int) {
        expiresAt = Date().addingTimeInterval(TimeInterval(minutes * 60))
    }

    static func deactivate() {
        expiresAt = nil
    }
}
