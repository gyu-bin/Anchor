//
//  WidgetSync.swift
//  Anchor
//

import Foundation
import SwiftData

@MainActor
enum WidgetSync {
    /// 오늘 할 일(항목) 기준 진행률 — 앱 「N개 / M개 했어요」와 동일
    static func refresh(modelContext: ModelContext, routines: [Routine]) {
        let vm = TodayViewModel()
        let withItems = vm.actionableRoutinesForToday(routines)
        let isLockActive = ShieldManager.isAnyActivelyLocking(
            routines: withItems,
            modelContext: modelContext
        )
        let lockRoutine = withItems.first {
            ShieldManager.isActivelyLocking(routine: $0, modelContext: modelContext)
        }

        guard !withItems.isEmpty else {
            WidgetDataStore.publish(
                progressPercent: 0,
                completedItemCount: 0,
                totalItemCount: 0,
                remainingItems: [],
                isLockActive: isLockActive,
                lockRoutineName: isLockActive ? lockRoutine?.name : nil
            )
            return
        }

        var totalItems = 0
        var completedItems = 0
        var remaining: [WidgetPendingItem] = []

        for routine in withItems {
            let items = vm.sortedItems(for: routine)
            totalItems += items.count
            guard let log = try? vm.todayLog(for: routine, context: modelContext) else { continue }
            for item in items where !log.completedItems.contains(item.id) {
                remaining.append(WidgetPendingItem(
                    itemName: item.name,
                    routineName: routine.name,
                    icon: item.icon
                ))
            }
            completedItems += items.filter { log.completedItems.contains($0.id) }.count
        }

        let progress = totalItems == 0
            ? 0
            : Int((Double(completedItems) / Double(totalItems) * 100).rounded())

        WidgetDataStore.publish(
            progressPercent: progress,
            completedItemCount: completedItems,
            totalItemCount: totalItems,
            remainingItems: remaining,
            isLockActive: isLockActive,
            lockRoutineName: isLockActive ? lockRoutine?.name : nil
        )
    }
}
