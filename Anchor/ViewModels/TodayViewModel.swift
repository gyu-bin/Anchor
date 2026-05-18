//
//  TodayViewModel.swift
//  Anchor
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
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
        let day = Date().startOfDay(in: calendar)
        let rid = routine.id
        var fd = FetchDescriptor<DailyLog>(
            predicate: #Predicate { log in
                log.routineId == rid
            }
        )
        fd.fetchLimit = 200
        let logs = try context.fetch(fd)
        if let existing = logs.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
            return existing
        }
        let log = DailyLog(date: day, routineId: routine.id, completedItems: [], isFullyCompleted: false, totalMinutes: 0)
        context.insert(log)
        return log
    }

    func refreshCompletionState(log: DailyLog, routine: Routine) {
        let items = routine.items
        let completed = Set(log.completedItems)
        let allIds = Set(items.map(\.id))
        log.isFullyCompleted = !allIds.isEmpty && allIds.isSubset(of: completed)
        log.totalMinutes = log.completedItems.count
    }

    func toggleCompletion(item: RoutineItem, routine: Routine, context: ModelContext) throws {
        let log = try todayLog(for: routine, context: context)
        var set = Set(log.completedItems)
        if set.contains(item.id) {
            set.remove(item.id)
        } else {
            set.insert(item.id)
        }
        log.completedItems = Array(set)
        refreshCompletionState(log: log, routine: routine)
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
            set.remove(item.id)
        }
        log.completedItems = Array(set)
        refreshCompletionState(log: log, routine: routine)
    }

    func completeNextItem(routines: [Routine], context: ModelContext) throws -> Bool {
        for routine in routinesForToday(routines) {
            let log = try todayLog(for: routine, context: context)
            if let item = firstIncompleteItem(routine: routine, log: log) {
                try setCompletion(item: item, routine: routine, completed: true, context: context)
                return true
            }
        }
        return false
    }

    func isCompleted(_ item: RoutineItem, log: DailyLog) -> Bool {
        log.completedItems.contains(item.id)
    }

    func progress(routine: Routine, log: DailyLog) -> Double {
        let total = routine.items.count
        guard total > 0 else { return 0 }
        let done = log.completedItems.filter { id in routine.items.contains(where: { $0.id == id }) }.count
        return Double(done) / Double(total)
    }

    func firstIncompleteItem(routine: Routine, log: DailyLog) -> RoutineItem? {
        sortedItems(for: routine).first { !log.completedItems.contains($0.id) }
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
        let withItems = routinesForToday(routines)
        guard !withItems.isEmpty else { return false }
        for r in withItems {
            let log = try todayLog(for: r, context: context)
            if !log.isFullyCompleted { return false }
        }
        return true
    }
}
