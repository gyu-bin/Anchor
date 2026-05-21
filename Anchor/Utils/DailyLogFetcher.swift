//
//  DailyLogFetcher.swift
//  Anchor
//

import Foundation
import SwiftData

@MainActor
enum DailyLogFetcher {
    static func log(id: UUID, context: ModelContext) -> DailyLog? {
        context.processPendingChanges()
        let targetId = id
        var fd = FetchDescriptor<DailyLog>(
            predicate: #Predicate<DailyLog> { log in
                log.id == targetId
            }
        )
        fd.fetchLimit = 1
        return try? context.fetch(fd).first
    }

    static func todayLog(
        for routine: Routine,
        context: ModelContext,
        calendar: Calendar = .current,
        createIfMissing: Bool = true
    ) throws -> DailyLog? {
        context.processPendingChanges()
        let day = Date().startOfDay(in: calendar)
        let rid = routine.id
        var fd = FetchDescriptor<DailyLog>(
            predicate: #Predicate<DailyLog> { log in
                log.routineId == rid
            }
        )
        fd.fetchLimit = 64
        let logs = try context.fetch(fd)
        if let existing = logs.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
            if let fresh = log(id: existing.id, context: context) {
                return fresh
            }
            context.delete(existing)
            try? context.save()
            context.processPendingChanges()
        }
        guard createIfMissing else { return nil }
        let log = DailyLog(
            date: day,
            routineId: routine.id,
            completedItems: [],
            isFullyCompleted: false,
            totalMinutes: 0
        )
        context.insert(log)
        return log
    }

    /// 분석·위젯용 — 삭제된 루틴 로그는 제외한 최신 fetch 결과만 반환합니다.
    static func fetchedLogs(
        liveRoutineIds: Set<UUID>,
        context: ModelContext,
        minimumDate: Date? = nil
    ) -> [DailyLog] {
        context.processPendingChanges()
        guard let all = try? context.fetch(
            FetchDescriptor<DailyLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        ) else { return [] }
        return all.filter { log in
            guard liveRoutineIds.contains(log.routineId) else { return false }
            if let minimumDate { return log.date >= minimumDate }
            return true
        }
    }
}
