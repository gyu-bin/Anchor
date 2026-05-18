//
//  RoutineItem.swift
//  Anchor
//

import Foundation
import SwiftData

@Model
final class RoutineItem {
    var id: UUID
    var name: String
    /// 분 단위
    var duration: Int
    var icon: String
    var order: Int
    var routine: Routine?

    init(
        id: UUID = UUID(),
        name: String,
        duration: Int,
        icon: String,
        order: Int = 0,
        routine: Routine? = nil
    ) {
        self.id = id
        self.name = name
        self.duration = duration
        self.icon = icon
        self.order = order
        self.routine = routine
    }
}
