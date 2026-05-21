//
//  RoutineViewModel.swift
//  Anchor
//

import Foundation
import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class RoutineViewModel {
    static let iconChoices: [String] = [
        "book", "figure.run", "brain.head.profile", "pencil",
        "music.note", "cup.and.saucer", "heart", "moon",
        "leaf", "flame", "bolt", "house",
        "bed.double", "sun.max", "note.text", "books.vertical"
    ]

    func sortedRoutines(_ allRoutines: [Routine]) -> [Routine] {
        allRoutines.sorted { $0.order < $1.order }
    }

    func nextOrder(in allRoutines: [Routine]) -> Int {
        (allRoutines.map(\.order).max() ?? -1) + 1
    }

    @discardableResult
    func addRoutine(
        name: String,
        schedule: RoutineScheduleDraft,
        context: ModelContext,
        routines: [Routine]
    ) -> Routine {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = trimmed.isEmpty ? "새 루틴" : trimmed
        let r = Routine(
            name: displayName,
            startTime: schedule.startTime,
            order: nextOrder(in: routines)
        )
        RoutineSchedule.apply(schedule, to: r)
        context.insert(r)
        try? context.save()
        return r
    }

    func updateSchedule(_ routine: Routine, draft: RoutineScheduleDraft, context: ModelContext) {
        guard RoutineSchedule.isDraftValid(draft) else { return }
        RoutineSchedule.apply(draft, to: routine)
        try? context.save()
        RoutineSync.afterMutation(modelContext: context, refreshShield: false)
    }

    func deleteRoutine(_ routine: Routine, context: ModelContext) {
        RoutineDeletion.delete(routine, context: context)
        Task { @MainActor in
            context.processPendingChanges()
            await Task.yield()
            RoutineSync.afterMutation(modelContext: context, immediately: true)
        }
    }

    func addItem(
        to routine: Routine,
        name: String,
        icon: String,
        duration: Int = 0,
        context: ModelContext
    ) {
        let next = (routine.items.map(\.order).max() ?? -1) + 1
        let item = RoutineItem(name: name, duration: max(0, duration), icon: icon, order: next, routine: routine)
        context.insert(item)
        routine.items.append(item)
        try? context.save()
        RoutineSync.afterMutation(modelContext: context)
    }

    func updateItem(
        _ item: RoutineItem,
        name: String,
        icon: String,
        duration: Int,
        context: ModelContext
    ) {
        item.name = name
        item.icon = icon
        item.duration = max(0, duration)
        try? context.save()
        RoutineSync.afterMutation(modelContext: context)
    }

    @discardableResult
    func createRoutine(
        from template: RoutineTemplate,
        context: ModelContext,
        routines: [Routine]
    ) -> Routine {
        let routine = RoutineTemplateStore.createRoutine(
            from: template,
            context: context,
            routines: routines,
            order: nextOrder(in: routines)
        )
        try? context.save()
        RoutineSync.afterMutation(modelContext: context, refreshShield: false)
        return routine
    }

    @discardableResult
    func duplicateRoutine(
        _ source: Routine,
        context: ModelContext,
        routines: [Routine]
    ) -> Routine {
        let copy = Routine(
            name: "\(source.name) 복사",
            startTime: source.startTime,
            order: nextOrder(in: routines),
            blockedApps: source.blockedApps,
            blockedWebs: source.resolvedBlockedWebs(in: context),
            shieldSelectionData: source.shieldSelectionData,
            scheduleKindRaw: source.scheduleKindRaw,
            activeWeekdays: source.activeWeekdays,
            oneTimeDate: source.oneTimeDate,
            scheduleStartDate: source.scheduleStartDate,
            scheduleEndDate: source.scheduleEndDate,
            expiryActionRaw: source.expiryActionRaw,
            isArchived: false
        )
        copy.endTime = source.endTime
        context.insert(copy)
        for item in source.items.sorted(by: { $0.order < $1.order }) {
            let newItem = RoutineItem(
                name: item.name,
                duration: item.duration,
                icon: item.icon,
                order: item.order,
                routine: copy
            )
            context.insert(newItem)
            copy.items.append(newItem)
        }
        try? context.save()
        RoutineSync.afterMutation(modelContext: context)
        return copy
    }

    func deleteItem(_ item: RoutineItem, context: ModelContext) {
        context.delete(item)
        try? context.save()
        RoutineSync.afterMutation(modelContext: context)
    }

    func deleteItems(at offsets: IndexSet, in routine: Routine, context: ModelContext) {
        let sorted = routine.items.sorted { $0.order < $1.order }
        for index in offsets {
            context.delete(sorted[index])
        }
        try? context.save()
        RoutineSync.afterMutation(modelContext: context)
    }

    func moveItem(from source: IndexSet, to destination: Int, in routine: Routine, context: ModelContext) {
        var items = routine.items.sorted { $0.order < $1.order }
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.order = index
        }
        try? context.save()
    }

    func moveRoutine(from source: IndexSet, to destination: Int, routines: [Routine], context: ModelContext) {
        var ordered = sortedRoutines(routines)
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, routine) in ordered.enumerated() {
            routine.order = index
        }
        try? context.save()
        RoutineSync.afterMutation(modelContext: context, refreshShield: false)
    }

    func normalizeDomain(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .split(separator: "/").first.map(String.init) ?? ""
    }

    func addBlockedWeb(_ domain: String, to routine: Routine, context: ModelContext) {
        let d = normalizeDomain(domain)
        guard !d.isEmpty else { return }
        if routine.resolvedBlockedWebs(in: context).contains(d) { return }
        routine.blockedWebs.append(d)
        try? context.save()
        RoutineSync.afterMutation(modelContext: context)
    }

    func removeBlockedWeb(_ domain: String, from routine: Routine, context: ModelContext) {
        routine.blockedWebs.removeAll { $0 == domain }
        try? context.save()
        RoutineSync.afterMutation(modelContext: context)
    }
}
