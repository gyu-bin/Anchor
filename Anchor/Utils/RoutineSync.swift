//
//  RoutineSync.swift
//  Anchor
//

import Foundation
import SwiftData

/// 루틴·로그 변경 후 알림·위젯·잠금을 한곳에서 맞춥니다.
@MainActor
enum RoutineSync {
    static func afterMutation(
        modelContext: ModelContext,
        refreshShield: Bool = true
    ) {
        try? NotificationManager.rescheduleAll(modelContext: modelContext)
        let descriptor = FetchDescriptor<Routine>(sortBy: [SortDescriptor(\.order)])
        let routines = (try? modelContext.fetch(descriptor)) ?? []
        WidgetSync.refresh(modelContext: modelContext, routines: routines)
        NotificationManager.refreshDailyClosureNotifications(modelContext: modelContext)
        if refreshShield {
            Task { await ShieldManager.refresh(modelContext: modelContext) }
        }
    }
}
