//
//  RoutineTemplateItem.swift
//  Anchor
//

import Foundation
import SwiftData

@Model
final class RoutineTemplateItem {
    var name: String
    var duration: Int
    var icon: String
    var order: Int
    var template: RoutineTemplate?

    init(name: String, duration: Int, icon: String, order: Int, template: RoutineTemplate? = nil) {
        self.name = name
        self.duration = duration
        self.icon = icon
        self.order = order
        self.template = template
    }
}
