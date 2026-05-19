//
//  RoutineScheduleRangeTests.swift
//  AnchorTests
//

import Foundation
import SwiftData
import Testing
@testable import Keyring

struct RoutineScheduleRangeTests {
  @MainActor
  @Test func period_onlyWithinRange() throws {
    let cal = TestFixtures.utcCalendar()
    let (_, ctx) = try TestFixtures.makeInMemoryContext()

    var draft = RoutineScheduleDraft()
    draft.kind = .period
    draft.scheduleStartDate = TestFixtures.date(year: 2026, month: 5, day: 18, calendar: cal)
    draft.scheduleEndDate = TestFixtures.date(year: 2026, month: 5, day: 20, calendar: cal)
    draft.activeWeekdays = [2, 3, 4]

    let routine = Routine(name: "이번 주", startTime: draft.startTime, order: 0)
    RoutineSchedule.apply(draft, to: routine, calendar: cal)
    ctx.insert(routine)

    let mon = TestFixtures.date(year: 2026, month: 5, day: 18, calendar: cal)
    let thu = TestFixtures.date(year: 2026, month: 5, day: 21, calendar: cal)
    let after = TestFixtures.date(year: 2026, month: 5, day: 25, calendar: cal)

    #expect(RoutineSchedule.isActive(routine, on: mon, calendar: cal))
    #expect(!RoutineSchedule.isActive(routine, on: thu, calendar: cal))
    #expect(!RoutineSchedule.isActive(routine, on: after, calendar: cal))
    #expect(RoutineSchedule.isExpired(routine, on: after, calendar: cal))
  }

  @MainActor
  @Test func expired_withEndDate_savesTemplateBeforeDelete() throws {
    let cal = TestFixtures.utcCalendar()
    let (_, ctx) = try TestFixtures.makeInMemoryContext()

    var draft = RoutineScheduleDraft()
    draft.kind = .once
    draft.oneTimeDate = TestFixtures.date(year: 2026, month: 5, day: 10, calendar: cal)
    let routine = Routine(name: "지난 루틴", startTime: draft.startTime, order: 0)
    RoutineSchedule.apply(draft, to: routine, calendar: cal)
    let item = RoutineItem(name: "스트레칭", duration: 5, icon: "figure.run", order: 0, routine: routine)
    ctx.insert(routine)
    ctx.insert(item)
    routine.items.append(item)

    let after = TestFixtures.date(year: 2026, month: 5, day: 18, calendar: cal)
    #expect(RoutineSchedule.isExpired(routine, on: after, calendar: cal))

    RoutineTemplateStore.save(from: routine, context: ctx)
    let templates = RoutineTemplateStore.sortedTemplates(context: ctx)
    #expect(templates.count == 1)
    #expect(templates[0].name == "지난 루틴")
    #expect(templates[0].items.count == 1)
  }

  @MainActor
  @Test func weekdays_withEndDate_stopsAfterEnd() throws {
    let cal = TestFixtures.utcCalendar()
    let (_, ctx) = try TestFixtures.makeInMemoryContext()

    var draft = RoutineScheduleDraft()
    draft.kind = .weekdays
    draft.activeWeekdays = [2]
    draft.hasScheduleEnd = true
    draft.scheduleEndDate = TestFixtures.date(year: 2026, month: 5, day: 18, calendar: cal)

    let routine = Routine(name: "월요일만", startTime: draft.startTime, order: 0)
    RoutineSchedule.apply(draft, to: routine, calendar: cal)
    ctx.insert(routine)

    let mon = TestFixtures.date(year: 2026, month: 5, day: 18, calendar: cal)
    let laterMon = TestFixtures.date(year: 2026, month: 5, day: 25, calendar: cal)

    #expect(RoutineSchedule.isActive(routine, on: mon, calendar: cal))
    #expect(!RoutineSchedule.isActive(routine, on: laterMon, calendar: cal))
    #expect(RoutineSchedule.isExpired(routine, on: laterMon, calendar: cal))
  }
}
