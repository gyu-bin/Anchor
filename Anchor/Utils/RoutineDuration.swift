//
//  RoutineDuration.swift
//  Anchor
//

import Foundation

enum RoutineDuration {
    static func totalMinutes(items: [RoutineItem]) -> Int {
        items.reduce(0) { $0 + max(0, $1.duration) }
    }

    static func formattedTotal(items: [RoutineItem]) -> String? {
        let total = totalMinutes(items: items)
        guard total > 0 else { return nil }
        if total < 60 {
            return AppCopy.Routine.durationMinutes(total)
        }
        let hours = total / 60
        let mins = total % 60
        if mins == 0 {
            return AppCopy.Routine.durationHours(hours)
        }
        return AppCopy.Routine.durationHoursMinutes(hours: hours, minutes: mins)
    }
}
