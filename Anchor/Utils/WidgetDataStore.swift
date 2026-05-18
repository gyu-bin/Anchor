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
    static let nextItemKey = "widget.nextItemName"
    static let nextRoutineKey = "widget.nextRoutineName"
    static let lockActiveKey = "widget.lockActive"
    static let lockRoutineKey = "widget.lockRoutineName"
    static let todayProgressKind = "TodayProgress"
    static let lockStatusKind = "LockStatus"

    static func publish(
        progressPercent: Int,
        nextItemName: String?,
        nextRoutineName: String?,
        isLockActive: Bool,
        lockRoutineName: String?
    ) {
        let clamped = min(100, max(0, progressPercent))
        SharedShieldStore.suite?.set(clamped, forKey: progressKey)
        SharedShieldStore.suite?.set(nextItemName, forKey: nextItemKey)
        SharedShieldStore.suite?.set(nextRoutineName, forKey: nextRoutineKey)
        SharedShieldStore.suite?.set(isLockActive, forKey: lockActiveKey)
        SharedShieldStore.suite?.set(lockRoutineName, forKey: lockRoutineKey)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: todayProgressKind)
        WidgetCenter.shared.reloadTimelines(ofKind: lockStatusKind)
        #endif
    }

    static func read() -> (progress: Int, nextItem: String?, nextRoutine: String?) {
        let suite = SharedShieldStore.suite
        let progress = suite?.integer(forKey: progressKey) ?? 0
        return (
            progress,
            suite?.string(forKey: nextItemKey),
            suite?.string(forKey: nextRoutineKey)
        )
    }
}
