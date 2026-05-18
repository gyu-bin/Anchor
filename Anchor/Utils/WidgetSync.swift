//
//  WidgetSync.swift
//  Anchor
//

import Foundation
import SwiftData

@MainActor
enum WidgetSync {
    static func refresh(modelContext: ModelContext, routines: [Routine]) {
        let vm = TodayViewModel()
        let withItems = vm.routinesForToday(routines)
        guard !withItems.isEmpty else {
            WidgetDataStore.publish(progressPercent: 0, nextItemName: nil, nextRoutineName: nil)
            return
        }

        var completedRoutines = 0
        var nextItem: RoutineItem?
        var nextRoutine: Routine?

        for routine in withItems {
            guard let log = try? vm.todayLog(for: routine, context: modelContext) else { continue }
            if log.isFullyCompleted {
                completedRoutines += 1
            } else if nextItem == nil, let item = vm.firstIncompleteItem(routine: routine, log: log) {
                nextItem = item
                nextRoutine = routine
            }
        }

        let progress = Int((Double(completedRoutines) / Double(withItems.count) * 100).rounded())
        WidgetDataStore.publish(
            progressPercent: progress,
            nextItemName: nextItem?.name,
            nextRoutineName: nextRoutine?.name
        )
    }
}
