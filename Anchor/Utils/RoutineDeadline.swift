//
//  RoutineDeadline.swift
//  Anchor
//

import Foundation

enum RoutineDeadline {
  /// 마감 시각(오늘). `endTime` 미설정이면 nil.
  static func endTimeToday(
    for routine: Routine,
    now: Date = Date(),
    calendar: Calendar = .current
  ) -> Date? {
    guard let end = routine.endTime else { return nil }
    let comps = calendar.dateComponents([.hour, .minute], from: end)
    guard let hour = comps.hour, let minute = comps.minute else { return nil }
    guard let base = calendar.date(
      bySettingHour: hour,
      minute: minute,
      second: 0,
      of: calendar.startOfDay(for: now)
    ) else { return nil }
    let extra = RoutineDeadlineExtensionStore.extraMinutes(
      routineID: routine.id,
      on: now,
      calendar: calendar
    )
    guard extra > 0 else { return base }
    return calendar.date(byAdding: .minute, value: extra, to: base)
  }

  /// 오늘 루틴 마감(연장 반영)이 지났는지. `endTime` 없거나 아직 시작 전이면 false.
  static func isTodayDeadlinePassed(
    for routine: Routine,
    now: Date = Date(),
    calendar: Calendar = .current
  ) -> Bool {
    guard routine.endTime != nil, !routine.items.isEmpty else { return false }
    guard hasRoutineStartedToday(routine, now: now, calendar: calendar) else { return false }
    guard let end = endTimeToday(for: routine, now: now, calendar: calendar) else { return false }
    return now >= end
  }

  /// 종료 시간이 있고, 마감 전 1시간~자동 해제 전이며, 오늘 연장 횟수가 남아 있을 때.
  static func canExtendDeadlineToday(
    for routine: Routine,
    isComplete: Bool,
    now: Date = Date(),
    calendar: Calendar = .current
  ) -> Bool {
    guard routine.endTime != nil, !routine.items.isEmpty, !isComplete else { return false }
    guard RoutineDeadlineExtensionStore.remainingUses(
      routineID: routine.id,
      on: now,
      calendar: calendar
    ) > 0 else { return false }
    guard hasRoutineStartedToday(routine, now: now, calendar: calendar) else { return false }
    guard let end = endTimeToday(for: routine, now: now, calendar: calendar),
          let unlock = unlockTimeToday(for: routine, now: now, calendar: calendar),
          let windowStart = calendar.date(
            byAdding: .minute,
            value: -RoutineDeadlineExtensionStore.offerWindowMinutesBeforeEnd,
            to: end
          ) else { return false }
    return now >= windowStart && now < unlock
  }

  /// 미완료 시 잠금이 풀리는 시각. `endTime` 없으면 nil(완료할 때까지 유지).
  static func unlockTimeToday(
    for routine: Routine,
    now: Date = Date(),
    calendar: Calendar = .current
  ) -> Date? {
    endTimeToday(for: routine, now: now, calendar: calendar)
  }

  /// 시작 후 · 미완료 · (마감 전이거나 아직 unlock 시각 전)이면 잠금 유지.
  static func shouldKeepShield(
    routine: Routine,
    isComplete: Bool,
    now: Date = Date(),
    calendar: Calendar = .current
  ) -> Bool {
    if isComplete || routine.items.isEmpty { return false }
    guard hasRoutineStartedToday(routine, now: now, calendar: calendar) else { return false }
    guard let unlock = unlockTimeToday(for: routine, now: now, calendar: calendar) else {
      return true
    }
    return now < unlock
  }

  static func isFutureDay(_ day: Date, calendar: Calendar = .current, now: Date = Date()) -> Bool {
    calendar.startOfDay(for: day) > calendar.startOfDay(for: now)
  }

  /// 미완료 판정 가능한 시점인지 (과거 날짜, 또는 오늘 마감이 지난 뒤).
  static func isReadyToJudgeIncomplete(
    scheduled: [Routine],
    logs: [DailyLog],
    day: Date,
    calendar: Calendar = .current,
    now: Date = Date()
  ) -> Bool {
    guard !isFutureDay(day, calendar: calendar, now: now) else { return false }
    guard !scheduled.isEmpty else { return false }

    let dayStart = calendar.startOfDay(for: day)
    let todayStart = calendar.startOfDay(for: now)
    if dayStart < todayStart { return true }

    let dayLogs = logs.filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
    let map = Dictionary(uniqueKeysWithValues: dayLogs.map { ($0.routineId, $0) })

    for routine in scheduled {
      if map[routine.id]?.isFullyCompleted == true { continue }
      if let end = endTimeToday(for: routine, now: day, calendar: calendar) {
        if now >= end { return true }
      }
    }
    return false
  }

  static func isFullyComplete(
    _ routine: Routine,
    logs: [DailyLog],
    day: Date,
    calendar: Calendar
  ) -> Bool {
    let dayStart = calendar.startOfDay(for: day)
    let dayLogs = logs.filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
    guard let log = dayLogs.first(where: { $0.routineId == routine.id }) else { return false }
    return log.isFullyCompleted
  }

  private static func hasRoutineStartedToday(
    _ routine: Routine,
    now: Date,
    calendar: Calendar
  ) -> Bool {
    let comps = calendar.dateComponents([.hour, .minute], from: routine.startTime)
    guard let hour = comps.hour, let minute = comps.minute else { return true }
    guard let startToday = calendar.date(
      bySettingHour: hour,
      minute: minute,
      second: 0,
      of: calendar.startOfDay(for: now)
    ) else { return true }
    return now >= startToday
  }
}
