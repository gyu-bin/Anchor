//
//  DailyLog.swift
//  Anchor
//

import Foundation
import SwiftData

@Model
final class DailyLog {
    var id: UUID
    var date: Date
    var routineId: UUID
    var completedItems: [UUID]
    var isFullyCompleted: Bool
    var totalMinutes: Int

    init(
        id: UUID = UUID(),
        date: Date,
        routineId: UUID,
        completedItems: [UUID] = [],
        isFullyCompleted: Bool = false,
        totalMinutes: Int = 0
    ) {
        self.id = id
        self.date = date
        self.routineId = routineId
        self.completedItems = completedItems
        self.isFullyCompleted = isFullyCompleted
        self.totalMinutes = totalMinutes
    }
}
