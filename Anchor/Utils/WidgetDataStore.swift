//
//  WidgetDataStore.swift
//  Anchor
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetDataStore {
    static let progressKey = "widget.progressPercent"
    static let completedItemsKey = "widget.completedItemCount"
    static let totalItemsKey = "widget.totalItemCount"
    static let nextItemKey = "widget.nextItemName"
    static let nextRoutineKey = "widget.nextRoutineName"
    static let lockActiveKey = "widget.lockActive"
    static let lockRoutineKey = "widget.lockRoutineName"
    static let todayProgressKind = "TodayProgress"
    static let lockStatusKind = "LockStatus"

    static func publish(
        progressPercent: Int,
        completedItemCount: Int,
        totalItemCount: Int,
        remainingItems: [WidgetPendingItem],
        isLockActive: Bool,
        lockRoutineName: String?
    ) {
        let suite = SharedShieldStore.suite
        let clamped = min(100, max(0, progressPercent))
        suite?.set(clamped, forKey: progressKey)
        suite?.set(completedItemCount, forKey: completedItemsKey)
        suite?.set(totalItemCount, forKey: totalItemsKey)
        if let data = WidgetPendingItemCodec.encode(remainingItems) {
            suite?.set(data, forKey: WidgetPendingItemCodec.storageKey)
        } else {
            suite?.removeObject(forKey: WidgetPendingItemCodec.storageKey)
        }
        let first = remainingItems.first
        suite?.set(first?.itemName, forKey: nextItemKey)
        suite?.set(first?.routineName, forKey: nextRoutineKey)
        suite?.set(isLockActive, forKey: lockActiveKey)
        suite?.set(lockRoutineName, forKey: lockRoutineKey)
        reloadWidgetsImmediately()
    }

    static func reloadWidgetsImmediately() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: todayProgressKind)
        WidgetCenter.shared.reloadTimelines(ofKind: lockStatusKind)
        #endif
    }

    static func read() -> (progress: Int, completed: Int, total: Int, nextItem: String?, nextRoutine: String?) {
        let suite = SharedShieldStore.suite
        return (
            suite?.integer(forKey: progressKey) ?? 0,
            suite?.integer(forKey: completedItemsKey) ?? 0,
            suite?.integer(forKey: totalItemsKey) ?? 0,
            suite?.string(forKey: nextItemKey),
            suite?.string(forKey: nextRoutineKey)
        )
    }
}
