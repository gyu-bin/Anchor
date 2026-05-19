//
//  PremiumAndScheduleTests.swift
//  AnchorTests
//

import Foundation
import SwiftData
import Testing
@testable import Keyring

struct PremiumAndScheduleTests {
  @Test func historyCutoff_excludesDatesOlderThanFreeWindow() {
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    let recent = cal.date(byAdding: .day, value: -5, to: today)!
    let tooOld = cal.date(byAdding: .day, value: -31, to: today)!

    #expect(PremiumLimits.includesHistoryDate(today, isPremium: false, calendar: cal))
    #expect(PremiumLimits.includesHistoryDate(recent, isPremium: false, calendar: cal))
    #expect(!PremiumLimits.includesHistoryDate(tooOld, isPremium: false, calendar: cal))
    #expect(PremiumLimits.includesHistoryDate(tooOld, isPremium: true, calendar: cal))
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
