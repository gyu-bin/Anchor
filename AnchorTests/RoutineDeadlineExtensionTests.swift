//
//  RoutineDeadlineExtensionTests.swift
//  AnchorTests
//

import Foundation
import Testing
@testable import Keyring

struct RoutineDeadlineExtensionTests {
  private func clearExtension(routineID: UUID, calendar: Calendar = .current) {
    let dayKey = RoutineDeadlineExtensionStore.dayKey(for: Date(), calendar: calendar)
    SharedShieldStore.suite?.removeObject(forKey: "deadline.extMin.\(dayKey).\(routineID.uuidString)")
    SharedShieldStore.suite?.removeObject(forKey: "deadline.extUses.\(dayKey).\(routineID.uuidString)")
  }

  private func routineEndingInTwoHours(calendar: Calendar = .current) -> (Routine, Date)? {
    let now = Date()
    guard let future = calendar.date(byAdding: .minute, value: 120, to: now),
          calendar.isDate(future, inSameDayAs: now) else { return nil }
    let hour = calendar.component(.hour, from: future)
    let minute = calendar.component(.minute, from: future)
    guard let endStored = calendar.date(
      bySettingHour: hour,
      minute: minute,
      second: 0,
      of: now
    ), endStored > now else { return nil }
    let start = calendar.date(byAdding: .hour, value: -3, to: now) ?? now
    let routine = Routine(name: "아침", startTime: start, order: 0)
    routine.endTime = endStored
    return (routine, now)
  }

  @Test func endTimeToday_includesExtensionMinutes() {
    let cal = Calendar.current
    guard let (routine, now) = routineEndingInTwoHours(calendar: cal) else { return }
    clearExtension(routineID: routine.id, calendar: cal)

    let before = RoutineDeadline.endTimeToday(for: routine, now: now, calendar: cal)
    #expect(RoutineDeadlineExtensionStore.applyExtension(routineID: routine.id, on: now, calendar: cal))
    let after = RoutineDeadline.endTimeToday(for: routine, now: now, calendar: cal)

    #expect(before != nil)
    #expect(after == cal.date(byAdding: .minute, value: 30, to: before!))
    clearExtension(routineID: routine.id, calendar: cal)
  }

  @Test func applyExtension_respectsDailyLimit() {
    let cal = Calendar.current
    let routineID = UUID()
    clearExtension(routineID: routineID, calendar: cal)

    #expect(RoutineDeadlineExtensionStore.applyExtension(routineID: routineID, calendar: cal))
    #expect(RoutineDeadlineExtensionStore.applyExtension(routineID: routineID, calendar: cal))
    #expect(!RoutineDeadlineExtensionStore.applyExtension(routineID: routineID, calendar: cal))
    #expect(RoutineDeadlineExtensionStore.remainingUses(routineID: routineID, calendar: cal) == 0)
    #expect(RoutineDeadlineExtensionStore.extraMinutes(routineID: routineID, calendar: cal) == 60)
    clearExtension(routineID: routineID, calendar: cal)
  }

  @Test func canExtendDeadlineToday_onlyInsideWindow() {
    let cal = Calendar.current
    guard let (routine, now) = routineEndingInTwoHours(calendar: cal) else { return }
    clearExtension(routineID: routine.id, calendar: cal)

    guard let baseEnd = RoutineDeadline.endTimeToday(for: routine, now: now, calendar: cal),
          let windowStart = cal.date(byAdding: .minute, value: -60, to: baseEnd),
          let beforeWindow = cal.date(byAdding: .minute, value: -5, to: windowStart),
          let inside = cal.date(byAdding: .minute, value: -30, to: baseEnd) else {
      Issue.record("Could not build window dates")
      return
    }

    #expect(
      !RoutineDeadline.canExtendDeadlineToday(
        for: routine,
        isComplete: false,
        now: beforeWindow,
        calendar: cal
      )
    )
    #expect(
      RoutineDeadline.canExtendDeadlineToday(
        for: routine,
        isComplete: false,
        now: inside,
        calendar: cal
      )
    )
    clearExtension(routineID: routine.id, calendar: cal)
  }
}
