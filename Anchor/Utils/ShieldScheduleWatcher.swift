//
//  ShieldScheduleWatcher.swift
//  Anchor
//

import FamilyControls
import Foundation
import SwiftData

/// 루틴 시작·마감 시각에 맞춰 잠금을 반영하고, 오늘 탭 UI를 갱신합니다 (앱이 켜져 있을 때).
@MainActor
enum ShieldScheduleWatcher {
    private static var scheduleTimers: [String: Timer] = [:]
    private static var pollTimer: Timer?
    private static weak var watchedContext: ModelContext?
    private static var lastShouldLock = false
    private static var lastScheduleUISignature = ""

    static func reschedule(modelContext: ModelContext) {
        watchedContext = modelContext
        cancelScheduleTimers()

        guard ShieldManager.authorizationStatus() == .approved,
              !RestDayStore.isRestToday() else { return }

        guard let routines = try? modelContext.fetch(FetchDescriptor<Routine>()) else { return }

        let calendar = Calendar.current
        let now = Date()

        for routine in routines where RoutineSchedule.isActive(routine, on: now, calendar: calendar) && !routine.items.isEmpty {
            if let startToday = startTimeToday(for: routine, calendar: calendar), now < startToday {
                scheduleFire(
                    key: "\(routine.id.uuidString).start",
                    at: startToday,
                    modelContext: modelContext
                )
            }

            if let endToday = RoutineDeadline.endTimeToday(for: routine, now: now, calendar: calendar),
               now < endToday {
                scheduleFire(
                    key: "\(routine.id.uuidString).end",
                    at: endToday,
                    modelContext: modelContext
                )
            }

            if routine.endTime != nil,
               let unlock = RoutineDeadline.unlockTimeToday(for: routine, now: now, calendar: calendar),
               now < unlock,
               unlock != RoutineDeadline.endTimeToday(for: routine, now: now, calendar: calendar) {
                scheduleFire(
                    key: "\(routine.id.uuidString).unlock",
                    at: unlock,
                    modelContext: modelContext
                )
            }
        }

        publishScheduleUIRefreshIfNeeded(modelContext: modelContext)
    }

    static func startPolling(modelContext: ModelContext) {
        watchedContext = modelContext
        pollTimer?.invalidate()
        publishScheduleUIRefreshIfNeeded(modelContext: modelContext)
        pollTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            Task { @MainActor in
                guard let ctx = watchedContext else { return }
                await tick(modelContext: ctx)
            }
        }
    }

    static func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    static func stopAll() {
        stopPolling()
        cancelScheduleTimers()
        watchedContext = nil
        lastShouldLock = false
        lastScheduleUISignature = ""
    }

    static func syncLockState(modelContext: ModelContext) {
        lastShouldLock = ShieldManager.shouldApplyShieldsNow(modelContext: modelContext)
    }

    static func scheduleUISignature(modelContext: ModelContext, now: Date = Date()) -> String {
        guard let routines = try? modelContext.fetch(FetchDescriptor<Routine>()) else { return "" }
        let calendar = Calendar.current
        var parts: [String] = []
        for routine in routines where RoutineSchedule.isActive(routine, on: now, calendar: calendar) && !routine.items.isEmpty {
            let started = ShieldManager.hasRoutineStartedToday(routine, now: now, calendar: calendar)
            let locking = ShieldManager.isActivelyLocking(routine: routine, modelContext: modelContext)
            let deadlinePassed = RoutineDeadline.isTodayDeadlinePassed(for: routine, now: now, calendar: calendar)
            parts.append("\(routine.id.uuidString):\(started):\(locking):\(deadlinePassed)")
        }
        return parts.joined(separator: "|")
    }

    private static func scheduleFire(key: String, at date: Date, modelContext: ModelContext) {
        let interval = date.timeIntervalSince(Date())
        let timer = Timer.scheduledTimer(withTimeInterval: max(0.05, interval), repeats: false) { _ in
            Task { @MainActor in
                publishScheduleUIRefreshIfNeeded(modelContext: modelContext)
                NotificationCenter.default.post(name: .anchorRefreshShield, object: nil)
                if let ctx = watchedContext {
                    ShieldScheduleWatcher.reschedule(modelContext: ctx)
                }
            }
        }
        scheduleTimers[key] = timer
    }

    private static func publishScheduleUIRefreshIfNeeded(modelContext: ModelContext) {
        let signature = scheduleUISignature(modelContext: modelContext)
        guard signature != lastScheduleUISignature else { return }
        lastScheduleUISignature = signature
        NotificationCenter.default.post(name: .anchorTodayScheduleRefresh, object: nil)
    }

    private static func cancelScheduleTimers() {
        for timer in scheduleTimers.values {
            timer.invalidate()
        }
        scheduleTimers.removeAll()
    }

    private static func tick(modelContext: ModelContext) async {
        publishScheduleUIRefreshIfNeeded(modelContext: modelContext)

        let shouldLock = ShieldManager.shouldApplyShieldsNow(modelContext: modelContext)
        if shouldLock != lastShouldLock {
            lastShouldLock = shouldLock
            await ShieldManager.refresh(modelContext: modelContext)
            return
        }
        if shouldLock {
            await ShieldManager.refresh(modelContext: modelContext)
        }
    }

    private static func startTimeToday(for routine: Routine, calendar: Calendar) -> Date? {
        let comps = calendar.dateComponents([.hour, .minute], from: routine.startTime)
        guard let hour = comps.hour, let minute = comps.minute else { return nil }
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: calendar.startOfDay(for: Date())
        )
    }
}
