//
//  ShieldScheduleWatcher.swift
//  Anchor
//

import FamilyControls
import Foundation
import SwiftData

/// 루틴 시작 시각에 맞춰 잠금을 즉시 반영합니다 (앱이 켜져 있을 때).
@MainActor
enum ShieldScheduleWatcher {
    private static var startTimers: [UUID: Timer] = [:]
    private static var pollTimer: Timer?
    private static weak var watchedContext: ModelContext?
    private static var lastShouldLock = false

    static func reschedule(modelContext: ModelContext) {
        watchedContext = modelContext
        cancelStartTimers()

        guard ShieldManager.authorizationStatus() == .approved,
              !RestDayStore.isRestToday() else { return }

        guard let routines = try? modelContext.fetch(FetchDescriptor<Routine>()) else { return }

        let calendar = Calendar.current
        let now = Date()

        for routine in routines where RoutineSchedule.isActive(routine, on: now, calendar: calendar) && !routine.items.isEmpty {
            guard let startToday = startTimeToday(for: routine, calendar: calendar) else { continue }

            if now >= startToday {
                continue
            }

            let interval = startToday.timeIntervalSince(now)
            let timer = Timer.scheduledTimer(withTimeInterval: max(0.05, interval), repeats: false) { _ in
                Task { @MainActor in
                    NotificationCenter.default.post(name: .anchorRefreshShield, object: nil)
                    if let ctx = watchedContext {
                        ShieldScheduleWatcher.reschedule(modelContext: ctx)
                    }
                }
            }
            startTimers[routine.id] = timer
        }
    }

    static func startPolling(modelContext: ModelContext) {
        watchedContext = modelContext
        pollTimer?.invalidate()
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
        cancelStartTimers()
        watchedContext = nil
        lastShouldLock = false
    }

    static func syncLockState(modelContext: ModelContext) {
        lastShouldLock = ShieldManager.shouldApplyShieldsNow(modelContext: modelContext)
    }

    private static func cancelStartTimers() {
        for timer in startTimers.values {
            timer.invalidate()
        }
        startTimers.removeAll()
    }

    private static func tick(modelContext: ModelContext) async {
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
