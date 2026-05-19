//
//  HistoryAnalyticsTests.swift
//  AnchorTests
//

import Foundation
import SwiftData
import Testing
@testable import Keyring

@MainActor
struct HistoryAnalyticsTests {
  @Test func dayStatus_fullWhenAllItemsCompleted() throws {
    let cal = TestFixtures.utcCalendar()
    let day = TestFixtures.date(year: 2026, month: 5, day: 19, calendar: cal)
    let (_, ctx) = try TestFixtures.makeInMemoryContext()

    let routine = TestFixtures.weekdayRoutine(
      name: "아침",
      weekdays: Set(2...6),
      startHour: 7,
      startMinute: 0,
      context: ctx,
      calendar: cal
    )
        let item = RoutineItem(name: "독서", duration: 0, icon: "book", order: 0, routine: routine)
    ctx.insert(item)
    routine.items = [item]

    let log = DailyLog(
      date: day.startOfDay(in: cal),
      routineId: routine.id,
      completedItems: [item.id],
      isFullyCompleted: true,
      totalMinutes: 1
    )
    ctx.insert(log)
    try ctx.save()

    let status = HistoryAnalytics.dayStatus(
      logs: [log],
      routines: [routine],
      day: day,
      cal: cal
    )
    #expect(status == .full)
  }

  @Test func dayStatus_noneWhenNoRoutineScheduled() throws {
    let cal = TestFixtures.utcCalendar()
    let sunday = TestFixtures.date(year: 2026, month: 5, day: 17, calendar: cal)
    let (_, ctx) = try TestFixtures.makeInMemoryContext()

    let routine = TestFixtures.weekdayRoutine(
      name: "평일만",
      weekdays: Set(2...6),
      startHour: 7,
      startMinute: 0,
      context: ctx,
      calendar: cal
    )
        let item = RoutineItem(name: "운동", duration: 0, icon: "figure.run", order: 0, routine: routine)
    ctx.insert(item)
    routine.items = [item]
    try ctx.save()

    let status = HistoryAnalytics.dayStatus(
      logs: [],
      routines: [routine],
      day: sunday,
      cal: cal
    )
    #expect(status == .none)
  }

  @Test func streak_countsConsecutiveFullDays() throws {
    let cal = Calendar.current
    let (_, ctx) = try TestFixtures.makeInMemoryContext()

    let routine = TestFixtures.weekdayRoutine(
      name: "매일",
      weekdays: Set(1...7),
      startHour: 7,
      startMinute: 0,
      context: ctx,
      calendar: cal
    )
        let item = RoutineItem(name: "명상", duration: 0, icon: "brain.head.profile", order: 0, routine: routine)
    ctx.insert(item)
    routine.items = [item]

    let today = cal.startOfDay(for: Date())
    guard let yesterday = cal.date(byAdding: .day, value: -1, to: today) else {
      Issue.record("캘린더 날짜 계산 실패")
      return
    }

    for day in [yesterday, today] {
      let log = DailyLog(
        date: day,
        routineId: routine.id,
        completedItems: [item.id],
        isFullyCompleted: true,
        totalMinutes: 1
      )
      ctx.insert(log)
    }
    try ctx.save()

    let logs = try ctx.fetch(FetchDescriptor<DailyLog>())
    let streak = HistoryAnalytics.streak(logs: logs, routines: [routine], cal: cal)
    #expect(streak >= 2)
  }
}
