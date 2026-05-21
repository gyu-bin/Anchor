//
//  TodayViewModel.swift
//  Anchor
//

import Foundation
import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class TodayViewModel {
    func sortedRoutines(_ routines: [Routine]) -> [Routine] {
        routines.sorted { $0.order < $1.order }
    }

    /// 오늘 일정에 해당하는 루틴 전부 (항목 없어도 포함).
    func routinesForToday(_ routines: [Routine], calendar: Calendar = .current) -> [Routine] {
        sortedRoutines(routines).filter {
            RoutineSchedule.isActive($0, on: Date(), calendar: calendar)
        }
    }

    /// 잠금·위젯 등 실제로 수행할 항목이 있는 오늘 루틴.
    func actionableRoutinesForToday(_ routines: [Routine], calendar: Calendar = .current) -> [Routine] {
        routinesForToday(routines, calendar: calendar).filter { !$0.items.isEmpty }
    }

    func sortedItems(for routine: Routine) -> [RoutineItem] {
        routine.items.sorted { $0.order < $1.order }
    }

    func todayLog(for routine: Routine, context: ModelContext, calendar: Calendar = .current) throws -> DailyLog {
        guard let log = try DailyLogFetcher.todayLog(for: routine, context: context, calendar: calendar) else {
            throw TodayLogError.missingLog
        }
        return log
    }

    func refreshCompletionState(log: DailyLog, routine: Routine, context: ModelContext) {
        guard let fresh = DailyLogFetcher.log(id: log.id, context: context) else { return }
        let allIds = Set(routine.items.map(\.id))
        let completed = Set(fresh.completedItems.filter { allIds.contains($0) })
        fresh.completedItems = Array(completed)
        fresh.isFullyCompleted = !allIds.isEmpty && allIds.isSubset(of: completed)
        fresh.totalMinutes = fresh.completedItems.count
    }

    func isRoutineComplete(routine: Routine, log: DailyLog, context: ModelContext) -> Bool {
        guard let fresh = DailyLogFetcher.log(id: log.id, context: context) else { return false }
        let allIds = Set(routine.items.map(\.id))
        guard !allIds.isEmpty else { return false }
        return allIds.isSubset(of: Set(fresh.completedItems))
    }

    func isRoutineComplete(routine: Routine, snapshot: TodayLogSnapshot) -> Bool {
        let allIds = Set(routine.items.map(\.id))
        guard !allIds.isEmpty else { return false }
        return allIds.isSubset(of: snapshot.completedItemIds)
    }

    /// 루틴 삭제·항목 변경 후 오늘 로그·완료 플래그를 현재 루틴 목록에 맞춥니다.
    func reconcileTodayState(
        routines: [Routine],
        context: ModelContext,
        calendar: Calendar = .current
    ) {
        let day = Date().startOfDay(in: calendar)
        let liveRoutineIds = Set(routines.map(\.id))
        let dayStart = day
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86400)

        var todayLogsDescriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate<DailyLog> { log in
                log.date >= dayStart && log.date < dayEnd
            }
        )
        todayLogsDescriptor.fetchLimit = 64
        if let todayLogs = try? context.fetch(todayLogsDescriptor) {
            for log in todayLogs where !liveRoutineIds.contains(log.routineId) {
                context.delete(log)
            }
        }
        if context.hasChanges {
            try? context.save()
            context.processPendingChanges()
        }

        for routine in actionableRoutinesForToday(routines, calendar: calendar) {
            guard let log = try? todayLog(for: routine, context: context, calendar: calendar) else { continue }
            refreshCompletionState(log: log, routine: routine, context: context)
        }
    }

    /// 마감이 지난 뒤 완료된 항목은 체크 해제할 수 없습니다.
    func canUncheckItem(
        _ item: RoutineItem,
        routine: Routine,
        logId: UUID,
        context: ModelContext,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard let fresh = DailyLogFetcher.log(id: logId, context: context) else { return true }
        guard fresh.completedItems.contains(item.id) else { return true }
        return !RoutineDeadline.isTodayDeadlinePassed(for: routine, now: now, calendar: calendar)
    }

    func canUncheckItem(
        _ item: RoutineItem,
        routine: Routine,
        snapshot: TodayLogSnapshot,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard snapshot.completedItemIds.contains(item.id) else { return true }
        return !RoutineDeadline.isTodayDeadlinePassed(for: routine, now: now, calendar: calendar)
    }

    func toggleCompletion(item: RoutineItem, routine: Routine, context: ModelContext) throws {
        let log = try todayLog(for: routine, context: context)
        var set = Set(log.completedItems)
        if set.contains(item.id) {
            guard canUncheckItem(item, routine: routine, logId: log.id, context: context) else { return }
            set.remove(item.id)
        } else {
            set.insert(item.id)
        }
        log.completedItems = Array(set)
        refreshCompletionState(log: log, routine: routine, context: context)
    }

    func setCompletion(
        item: RoutineItem,
        routine: Routine,
        completed: Bool,
        context: ModelContext
    ) throws {
        let log = try todayLog(for: routine, context: context)
        var set = Set(log.completedItems)
        if completed {
            set.insert(item.id)
        } else {
            guard canUncheckItem(item, routine: routine, logId: log.id, context: context) else { return }
            set.remove(item.id)
        }
        log.completedItems = Array(set)
        refreshCompletionState(log: log, routine: routine, context: context)
    }

    func completeNextItem(routines: [Routine], context: ModelContext) throws -> Bool {
        for routine in routinesForToday(routines) {
            guard let snap = TodayLogSnapshot.capture(for: routine, context: context),
                  let item = firstIncompleteItem(routine: routine, snapshot: snap) else { continue }
            try setCompletion(item: item, routine: routine, completed: true, context: context)
            return true
        }
        return false
    }

    func isCompleted(_ item: RoutineItem, snapshot: TodayLogSnapshot) -> Bool {
        snapshot.completedItemIds.contains(item.id)
    }

    func progress(routine: Routine, snapshot: TodayLogSnapshot) -> Double {
        let total = routine.items.count
        guard total > 0 else { return 0 }
        let done = snapshot.completedItemIds.filter { id in routine.items.contains(where: { $0.id == id }) }.count
        return Double(done) / Double(total)
    }

    func firstIncompleteItem(routine: Routine, snapshot: TodayLogSnapshot) -> RoutineItem? {
        sortedItems(for: routine).first { !snapshot.completedItemIds.contains($0.id) }
    }

    /// 목록 순서대로, 아직 끝내지 않은 첫 루틴을 "진행 중"으로 선택합니다.
    func headlineRoutine(routines: [Routine], context: ModelContext) throws -> Routine? {
        let sorted = routinesForToday(routines)
        for r in sorted {
            let log = try todayLog(for: r, context: context)
            if !log.isFullyCompleted { return r }
        }
        return sorted.first
    }

    func allRoutinesFullyCompletedToday(routines: [Routine], context: ModelContext) throws -> Bool {
        let withItems = actionableRoutinesForToday(routines)
        guard !withItems.isEmpty else { return false }
        for r in withItems {
            guard let snap = TodayLogSnapshot.capture(for: r, context: context) else { return false }
            if !isRoutineComplete(routine: r, snapshot: snap) { return false }
        }
        return true
    }
}

enum TodayLogError: Error {
    case missingLog
}
