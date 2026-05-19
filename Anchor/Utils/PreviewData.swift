//
//  PreviewData.swift
//  Anchor
//

import Foundation
import SwiftData

enum PreviewData {
    static var container: ModelContainer {
        let schema = Schema([
            Routine.self,
            RoutineItem.self,
            DailyLog.self,
            RoutineTemplate.self,
            RoutineTemplateItem.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let routine = Routine(name: "아침 루틴", startTime: Date(), order: 0)
        let i1 = RoutineItem(name: "독서", duration: 20, icon: "book", order: 0, routine: routine)
        let i2 = RoutineItem(name: "명상", duration: 10, icon: "brain.head.profile", order: 1, routine: routine)
        routine.items = [i1, i2]
        routine.blockedWebs = ["youtube.com"]
        container.mainContext.insert(routine)
        container.mainContext.insert(i1)
        container.mainContext.insert(i2)
        return container
    }
}
