//
//  ShieldAndTodayTests.swift
//  AnchorTests
//

import Foundation
import SwiftData
import Testing
@testable import Keyring

@MainActor
struct ShieldAndTodayTests {
  @Test func hasRoutineStarted_falseBeforeStartTime() {
    let cal = TestFixtures.utcCalendar()
    let start = TestFixtures.date(year: 2026, month: 5, day: 19, hour: 9, minute: 0, calendar: cal)
    let before = TestFixtures.date(year: 2026, month: 5, day: 19, hour: 8, minute: 30, calendar: cal)
    let routine = Routine(name: "아침", startTime: start, order: 0)

    #expect(!ShieldManager.hasRoutineStartedToday(routine, now: before, calendar: cal))
    #expect(ShieldManager.hasRoutineStartedToday(routine, now: start, calendar: cal))
  }

  @Test func todayViewModel_toggleCompletionMarksLogComplete() throws {
    let cal = TestFixtures.utcCalendar()
    let (_, ctx) = try TestFixtures.makeInMemoryContext()
    let vm = TodayViewModel()

    let routine = TestFixtures.weekdayRoutine(
      name: "테스트",
      weekdays: Set(1...7),
      startHour: 7,
      startMinute: 0,
      context: ctx,
      calendar: cal
    )
    let item = RoutineItem(name: "항목", duration: 0, icon: "book", order: 0, routine: routine)
    ctx.insert(item)
    routine.items = [item]
    try ctx.save()

    try vm.toggleCompletion(item: item, routine: routine, context: ctx)
    try ctx.save()

    let log = try vm.todayLog(for: routine, context: ctx, calendar: cal)
    #expect(log.isFullyCompleted)
    #expect(log.completedItems.contains(item.id))
  }

  @Test func routineViewModel_normalizeDomain_stripsScheme() {
    let vm = RoutineViewModel()
    #expect(vm.normalizeDomain("https://www.youtube.com/watch") == "www.youtube.com")
    #expect(vm.normalizeDomain("  Instagram.COM  ") == "instagram.com")
  }
}
