//
//  TodayProgressSnapshot.swift
//  Anchor
//

import Foundation
import SwiftData

/// 오늘 탭 상단 진행·잠금 카드용 집계.
struct TodayProgressSnapshot {
    let isActivelyLocking: Bool
    let lockingRoutineNames: [String]
    let remainingItemCount: Int

    static func make(
        routines: [Routine],
        logSnapshots: [TodayLogSnapshot],
        modelContext: ModelContext
    ) -> TodayProgressSnapshot {
        let routinesWithItems = routines.filter { !$0.items.isEmpty }
        var remaining = 0
        for routine in routinesWithItems {
            let snap = logSnapshots.first { $0.routineId == routine.id }
            let completed = snap?.completedItemIds ?? []
            remaining += routine.items.filter { !completed.contains($0.id) }.count
        }

        let lockingNames = routinesWithItems
            .filter { ShieldManager.isActivelyLocking(routine: $0, modelContext: modelContext) }
            .map(\.name)

        return TodayProgressSnapshot(
            isActivelyLocking: !lockingNames.isEmpty,
            lockingRoutineNames: lockingNames,
            remainingItemCount: remaining
        )
    }
}
