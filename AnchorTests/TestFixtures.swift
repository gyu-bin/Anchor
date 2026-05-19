//
//  TestFixtures.swift
//  AnchorTests
//

import Foundation
import SwiftData
@testable import Keyring

enum TestFixtures {
    static func utcCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    static func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        minute: Int = 0,
        calendar: Calendar = utcCalendar()
    ) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        comps.calendar = calendar
        return calendar.date(from: comps)!
    }

    @MainActor
    static func makeInMemoryContext() throws -> (ModelContainer, ModelContext) {
        let schema = Schema([
            Routine.self,
            RoutineItem.self,
            DailyLog.self,
            RoutineTemplate.self,
            RoutineTemplateItem.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return (container, container.mainContext)
    }

    @MainActor
    static func weekdayRoutine(
        name: String,
        weekdays: Set<Int>,
        startHour: Int,
        startMinute: Int,
        context: ModelContext,
        calendar: Calendar = utcCalendar()
    ) -> Routine {
        var draft = RoutineScheduleDraft()
        draft.kind = .weekdays
        draft.activeWeekdays = weekdays
        draft.startTime = date(
            year: 2026,
            month: 5,
            day: 19,
            hour: startHour,
            minute: startMinute,
            calendar: calendar
        )
        let routine = Routine(name: name, startTime: draft.startTime, order: 0)
        RoutineSchedule.apply(draft, to: routine, calendar: calendar)
        context.insert(routine)
        return routine
    }
}
