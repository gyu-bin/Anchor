//
//  RoutineTemplate.swift
//  Anchor
//

import Foundation
import SwiftData

/// 종료된 루틴 스냅샷 — 새 루틴 만들 때 불러오기용
@Model
final class RoutineTemplate {
    var id: UUID
    var name: String
    var savedAt: Date
    var scheduleKindRaw: String
    var activeWeekdays: [Int]?
    var oneTimeDate: Date?
    var scheduleStartDate: Date?
    var scheduleEndDate: Date?
    var startTime: Date
    var endTime: Date?
    var blockedApps: [String]
    var blockedWebs: [String]
    var shieldSelectionData: Data?

    @Relationship(deleteRule: .cascade, inverse: \RoutineTemplateItem.template)
    var items: [RoutineTemplateItem]

    init(
        id: UUID = UUID(),
        name: String,
        savedAt: Date = Date(),
        scheduleKindRaw: String,
        activeWeekdays: [Int]? = nil,
        oneTimeDate: Date? = nil,
        scheduleStartDate: Date? = nil,
        scheduleEndDate: Date? = nil,
        startTime: Date,
        endTime: Date? = nil,
        blockedApps: [String] = [],
        blockedWebs: [String] = [],
        shieldSelectionData: Data? = nil,
        items: [RoutineTemplateItem] = []
    ) {
        self.id = id
        self.name = name
        self.savedAt = savedAt
        self.scheduleKindRaw = scheduleKindRaw
        self.activeWeekdays = activeWeekdays
        self.oneTimeDate = oneTimeDate
        self.scheduleStartDate = scheduleStartDate
        self.scheduleEndDate = scheduleEndDate
        self.startTime = startTime
        self.endTime = endTime
        self.blockedApps = blockedApps
        self.blockedWebs = blockedWebs
        self.shieldSelectionData = shieldSelectionData
        self.items = items
    }
}
