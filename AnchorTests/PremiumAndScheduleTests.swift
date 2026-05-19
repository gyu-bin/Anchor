//
//  PremiumAndScheduleTests.swift
//  AnchorTests
//

import Foundation
import SwiftData
import Testing
@testable import Keyring

struct PremiumAndScheduleTests {
  @Test func history_freeTier_includesOnlyCurrentMonth() {
    let cal = Calendar.current
    let now = cal.startOfDay(for: Date())
    let monthStart = PremiumLimits.currentMonthStart(calendar: cal, now: now)
    let lastMonth = cal.date(byAdding: .month, value: -1, to: monthStart)!

    #expect(PremiumLimits.includesHistoryDate(now, isPremium: false, calendar: cal, now: now))
    #expect(PremiumLimits.includesHistoryDate(monthStart, isPremium: false, calendar: cal, now: now))
    #expect(!PremiumLimits.includesHistoryDate(lastMonth, isPremium: false, calendar: cal, now: now))
    #expect(PremiumLimits.includesHistoryDate(lastMonth, isPremium: true, calendar: cal, now: now))

    #expect(PremiumLimits.includesHistoryMonth(monthStart, isPremium: false, calendar: cal, now: now))
    #expect(!PremiumLimits.includesHistoryMonth(lastMonth, isPremium: false, calendar: cal, now: now))
  }

  @MainActor
  @Test func schedule_weekdays_onlyOnSelectedDays() throws {
    let cal = TestFixtures.utcCalendar()
    let monday = TestFixtures.date(year: 2026, month: 5, day: 18, calendar: cal)
    let sunday = TestFixtures.date(year: 2026, month: 5, day: 17, calendar: cal)
    let (_, ctx) = try TestFixtures.makeInMemoryContext()

    let routine = TestFixtures.weekdayRoutine(
      name: "평일",
      weekdays: Set(2...6),
      startHour: 8,
      startMinute: 0,
      context: ctx,
      calendar: cal
    )

    #expect(RoutineSchedule.isActive(routine, on: monday, calendar: cal))
    #expect(!RoutineSchedule.isActive(routine, on: sunday, calendar: cal))
  }
}
