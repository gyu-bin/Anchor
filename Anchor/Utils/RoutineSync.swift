//
//  RoutineSync.swift
//  Anchor
//

import Foundation
import SwiftData

/// 루틴·로그 변경 후 알림·위젯·잠금을 한곳에서 맞춥니다.
@MainActor
enum RoutineSync {
    private static var debounceTask: Task<Void, Never>?
    private static var heavyTask: Task<Void, Never>?

    private static let debounceInterval: Duration = .milliseconds(450)

    /// UI에 필요한 저장·오늘 로그 정리는 빠르게, 알림·위젯·Shield는 뒤로 미룹니다.
    static func afterMutation(
        modelContext: ModelContext,
        refreshShield: Bool = true,
        immediately: Bool = false
    ) {
        if immediately {
            debounceTask?.cancel()
            debounceTask = nil
            runFastPath(modelContext: modelContext)
            runHeavyWork(modelContext: modelContext, refreshShield: refreshShield)
            return
        }

        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: debounceInterval)
            guard !Task.isCancelled else { return }
            runFastPath(modelContext: modelContext)
            scheduleHeavyWork(modelContext: modelContext, refreshShield: refreshShield)
        }
    }

    private static func runFastPath(modelContext: ModelContext) {
        modelContext.processPendingChanges()
        RoutineScheduleMaintenance.run(modelContext: modelContext)
        let descriptor = FetchDescriptor<Routine>(sortBy: [SortDescriptor(\.order)])
        let routines = (try? modelContext.fetch(descriptor)) ?? []
        let todayVM = TodayViewModel()
        todayVM.reconcileTodayState(routines: routines, context: modelContext)
        try? modelContext.save()
    }

    private static func scheduleHeavyWork(modelContext: ModelContext, refreshShield: Bool) {
        heavyTask?.cancel()
        heavyTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }
            runHeavyWork(modelContext: modelContext, refreshShield: refreshShield)
        }
    }

    private static func runHeavyWork(modelContext: ModelContext, refreshShield: Bool) {
        let descriptor = FetchDescriptor<Routine>(sortBy: [SortDescriptor(\.order)])
        let routines = (try? modelContext.fetch(descriptor)) ?? []

        try? NotificationManager.rescheduleAll(modelContext: modelContext)
        WidgetSync.refresh(modelContext: modelContext, routines: routines)
        NotificationManager.refreshDailyClosureNotifications(modelContext: modelContext)
        WidgetDataStore.reloadWidgetsImmediately()
        if refreshShield {
            Task { await ShieldManager.refresh(modelContext: modelContext) }
        }
    }
}
