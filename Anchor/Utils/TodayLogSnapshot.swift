//
//  TodayLogSnapshot.swift
//  Anchor
//

import Foundation
import SwiftData

/// 오늘 탭 UI용 — `DailyLog` 모델 참조를 넘기지 않아 삭제 직후 detached fault 크래시를 막습니다.
struct TodayLogSnapshot: Equatable, Sendable {
    let logId: UUID
    let routineId: UUID
    let completedItemIds: Set<UUID>
    let isFullyCompleted: Bool

    @MainActor
    static func capture(
        for routine: Routine,
        context: ModelContext,
        calendar: Calendar = .current
    ) -> TodayLogSnapshot? {
        guard let log = try? DailyLogFetcher.todayLog(for: routine, context: context, calendar: calendar) else {
            return nil
        }
        return TodayLogSnapshot(
            logId: log.id,
            routineId: log.routineId,
            completedItemIds: Set(log.completedItems),
            isFullyCompleted: log.isFullyCompleted
        )
    }

    func log(for context: ModelContext) -> DailyLog? {
        DailyLogFetcher.log(id: logId, context: context)
    }
}
