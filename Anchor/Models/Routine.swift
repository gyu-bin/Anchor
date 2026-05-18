//
//  Routine.swift
//  Anchor
//

import Foundation
import SwiftData

@Model
final class Routine {
    var id: UUID
    var name: String
    var startTime: Date
    var order: Int
    @Relationship(deleteRule: .cascade, inverse: \RoutineItem.routine)
    var items: [RoutineItem]
    var blockedApps: [String]
    var blockedWebs: [String]
    /// `FamilyActivitySelection` PropertyList 인코딩 (차단할 앱 토큰).
    var shieldSelectionData: Data?

    init(
        id: UUID = UUID(),
        name: String,
        startTime: Date,
        order: Int = 0,
        items: [RoutineItem] = [],
        blockedApps: [String] = [],
        blockedWebs: [String] = [],
        shieldSelectionData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.order = order
        self.items = items
        self.blockedApps = blockedApps
        self.blockedWebs = blockedWebs
        self.shieldSelectionData = shieldSelectionData
    }
}
