//
//  RoutineViewModel.swift
//  Anchor
//

import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
final class RoutineViewModel: ObservableObject {
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

    func addRoutine(name: String, startTime: Date, context: ModelContext, routines: [Routine]) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = trimmed.isEmpty ? "새 루틴" : trimmed
        let r = Routine(
            name: displayName,
            startTime: startTime,
            order: nextOrder(in: routines)
        )
        context.insert(r)
        try? context.save()
        try? NotificationManager.rescheduleAll(modelContext: context)
    }

    func deleteRoutine(_ routine: Routine, context: ModelContext) {
        context.delete(routine)
        try? context.save()
        try? NotificationManager.rescheduleAll(modelContext: context)
    }

    func addItem(to routine: Routine, name: String, icon: String, context: ModelContext) {
        let next = (routine.items.map(\.order).max() ?? -1) + 1
        let item = RoutineItem(name: name, duration: 0, icon: icon, order: next, routine: routine)
        context.insert(item)
        routine.items.append(item)
        try? context.save()
        try? NotificationManager.rescheduleAll(modelContext: context)
    }

    func updateItem(_ item: RoutineItem, name: String, icon: String, context: ModelContext) {
        item.name = name
        item.icon = icon
        try? context.save()
        try? NotificationManager.rescheduleAll(modelContext: context)
    }

    func deleteItem(_ item: RoutineItem, context: ModelContext) {
        context.delete(item)
        try? context.save()
        try? NotificationManager.rescheduleAll(modelContext: context)
    }

    func deleteItems(at offsets: IndexSet, in routine: Routine, context: ModelContext) {
        let sorted = routine.items.sorted { $0.order < $1.order }
        for index in offsets {
            context.delete(sorted[index])
        }
        try? context.save()
        try? NotificationManager.rescheduleAll(modelContext: context)
    }

    func moveItem(from source: IndexSet, to destination: Int, in routine: Routine, context: ModelContext) {
        var items = routine.items.sorted { $0.order < $1.order }
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.order = index
        }
        try? context.save()
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
        if routine.blockedWebs.contains(d) { return }
        routine.blockedWebs.append(d)
        try? context.save()
    }

    func removeBlockedWeb(_ domain: String, from routine: Routine, context: ModelContext) {
        routine.blockedWebs.removeAll { $0 == domain }
        try? context.save()
    }
}
