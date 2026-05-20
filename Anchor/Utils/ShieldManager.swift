//
//  ShieldManager.swift
//  Anchor
//

import FamilyControls
import Foundation
import ManagedSettings
import Swift
import SwiftData

struct BlockedShieldSummary {
    var appTokens: [ApplicationToken]
    var webTokens: [WebDomainToken]
    var webDomains: [String]

    var hasAnyBlock: Bool {
        !appTokens.isEmpty || !webTokens.isEmpty || !webDomains.isEmpty
    }
}

/// 미완료 루틴이 있을 때 `ManagedSettings`로 선택된 앱·웹을 차단합니다.
@MainActor
enum ShieldManager {
    private static let settings = ManagedSettingsStore()

    static func authorizationStatus() -> AuthorizationStatus {
        AuthorizationCenter.shared.authorizationStatus
    }

    static func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }

    static func decodeSelection(_ data: Data?) -> FamilyActivitySelection {
        guard let data else { return FamilyActivitySelection() }
        return (try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)) ?? FamilyActivitySelection()
    }

    static func encodeSelection(_ selection: FamilyActivitySelection) throws -> Data {
        try PropertyListEncoder().encode(selection)
    }

    static func saveSelection(_ selection: FamilyActivitySelection, for routine: Routine, modelContext: ModelContext) throws {
        routine.shieldSelectionData = try encodeSelection(selection)
        try modelContext.save()
    }

    /// 오늘 기준으로 아직 끝나지 않은 루틴들의 차단을 시스템에 반영합니다.
    static func refresh(modelContext: ModelContext) async {
        defer { syncWidgetLockStatus(modelContext: modelContext) }

        guard authorizationStatus() == .approved else {
            settings.clearAllSettings()
            if let routines = try? modelContext.fetch(FetchDescriptor<Routine>()) {
                DeviceActivityScheduleManager.stopAllMonitoring(routines: routines)
            }
            SharedShieldStore.clearAll()
            return
        }

        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: Date())

        if TempUnlockStore.isActive {
            settings.clearAllSettings()
            SharedShieldStore.clearMergedSelection()
            return
        }

        if RestDayStore.isRestToday(calendar: calendar) {
            settings.clearAllSettings()
            if let routines = try? modelContext.fetch(FetchDescriptor<Routine>()) {
                DeviceActivityScheduleManager.stopAllMonitoring(routines: routines)
            }
            SharedShieldStore.clearMergedSelection()
            return
        }

        guard let routines = try? modelContext.fetch(FetchDescriptor<Routine>()) else {
            settings.clearAllSettings()
            return
        }

        processDeadlineGrace(
            routines: routines,
            dayStart: dayStart,
            calendar: calendar,
            modelContext: modelContext
        )

        let apps = activeBlockedApplicationTokens(
            routines: routines,
            dayStart: dayStart,
            calendar: calendar,
            modelContext: modelContext
        )
        let webTokens = activeBlockedWebDomainTokens(
            routines: routines,
            dayStart: dayStart,
            calendar: calendar,
            modelContext: modelContext
        )
        let webDomainStrings = activeBlockedWebDomainStrings(
            routines: routines,
            dayStart: dayStart,
            calendar: calendar,
            modelContext: modelContext
        )

        SharedShieldStore.saveBlockedWebDomainStrings(webDomainStrings)

        applyShieldSettings(apps: apps, webTokens: webTokens, webDomainStrings: webDomainStrings)

        await DeviceActivityScheduleManager.sync(modelContext: modelContext)

        // 모니터 재등록 직후 확장이 잠금을 비울 수 있어, 동기화 뒤 한 번 더 반영합니다.
        applyShieldSettings(
            apps: activeBlockedApplicationTokens(
                routines: routines,
                dayStart: dayStart,
                calendar: calendar,
                modelContext: modelContext
            ),
            webTokens: activeBlockedWebDomainTokens(
                routines: routines,
                dayStart: dayStart,
                calendar: calendar,
                modelContext: modelContext
            ),
            webDomainStrings: activeBlockedWebDomainStrings(
                routines: routines,
                dayStart: dayStart,
                calendar: calendar,
                modelContext: modelContext
            )
        )

        ShieldScheduleWatcher.reschedule(modelContext: modelContext)
        ShieldScheduleWatcher.syncLockState(modelContext: modelContext)
    }

    /// 지금 잠금이 걸려야 하는지 (UI·폴링용).
    static func shouldApplyShieldsNow(modelContext: ModelContext) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: Date())
        guard let routines = try? modelContext.fetch(FetchDescriptor<Routine>()) else { return false }
        return !activeBlockedApplicationTokens(
            routines: routines,
            dayStart: dayStart,
            calendar: calendar,
            modelContext: modelContext
        ).isEmpty
        || !activeBlockedWebDomainTokens(
            routines: routines,
            dayStart: dayStart,
            calendar: calendar,
            modelContext: modelContext
        ).isEmpty
        || !activeBlockedWebDomainStrings(
            routines: routines,
            dayStart: dayStart,
            calendar: calendar,
            modelContext: modelContext
        ).isEmpty
    }

    private static func applyShieldSettings(
        apps: [ApplicationToken],
        webTokens: [WebDomainToken],
        webDomainStrings: [String]
    ) {
        if apps.isEmpty && webTokens.isEmpty && webDomainStrings.isEmpty {
            settings.clearAllSettings()
        } else {
            settings.shield.applications = apps.isEmpty ? nil : Set(apps)
            WebDomainBlocking.apply(
                to: settings,
                webTokens: Set(webTokens),
                domainStrings: webDomainStrings
            )
        }
    }

    private static func syncWidgetLockStatus(modelContext: ModelContext) {
        guard let routines = try? modelContext.fetch(FetchDescriptor<Routine>()) else { return }
        WidgetSync.refresh(modelContext: modelContext, routines: routines)
    }

    /// 오늘 루틴 시작 시각(시·분)이 지났는지.
    static func hasRoutineStartedToday(_ routine: Routine, now: Date = Date(), calendar: Calendar = .current) -> Bool {
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

    static func isAnyActivelyLocking(routines: [Routine], modelContext: ModelContext) -> Bool {
        routines.contains { isActivelyLocking(routine: $0, modelContext: modelContext) }
    }

    /// 지금 실제로 잠금이 걸려야 하는지(시작 후 + 미완료 + 마감 유예 전).
    static func isActivelyLocking(routine: Routine, modelContext: ModelContext) -> Bool {
        if TempUnlockStore.isActive { return false }
        let summary = blockedSummary(for: routine, modelContext: modelContext)
        return summary.hasAnyBlock
    }

    static func routineLockMessage(routine: Routine, modelContext: ModelContext) -> String {
        if isActivelyLocking(routine: routine, modelContext: modelContext) {
            if let endTime = routine.endTime {
                let df = DateFormatter()
                df.locale = Locale(identifier: "ko_KR")
                df.dateFormat = "a h:mm"
                return "앱 잠금 중 · \(df.string(from: endTime))까지"
            }
            return AppCopy.Routine.lockActive
        }
        guard routine.endTime != nil else { return AppCopy.Routine.lockScheduled }

        let calendar = Calendar.current
        let now = Date()
        let dayStart = calendar.startOfDay(for: now)
        let complete = (try? routineIsFullyCompleteToday(
            routine,
            dayStart: dayStart,
            calendar: calendar,
            modelContext: modelContext
        )) ?? false
        if complete || routine.items.isEmpty { return AppCopy.Routine.lockScheduled }
        guard hasRoutineStartedToday(routine, now: now, calendar: calendar) else {
            return AppCopy.Routine.lockScheduled
        }
        guard let end = RoutineDeadline.endTimeToday(for: routine, now: now, calendar: calendar),
              let unlock = RoutineDeadline.unlockTimeToday(for: routine, now: now, calendar: calendar),
              now >= end else {
            return AppCopy.Routine.lockScheduled
        }
        if now >= unlock {
            return AppCopy.Routine.lockReleasedAfterDeadline
        }
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "a h:mm"
        return AppCopy.Routine.lockUnlocksAt(df.string(from: unlock))
    }

    private static func processDeadlineGrace(
        routines: [Routine],
        dayStart: Date,
        calendar: Calendar,
        modelContext: ModelContext,
        now: Date = Date()
    ) {
        let dayKey = DeadlineGraceStore.dayKey(for: now, calendar: calendar)
        var missedDeadlineToday = false

        for routine in routines where RoutineSchedule.isActive(routine, on: now, calendar: calendar) && !routine.items.isEmpty {
            guard routine.endTime != nil else { continue }
            let complete = (try? routineIsFullyCompleteToday(
                routine,
                dayStart: dayStart,
                calendar: calendar,
                modelContext: modelContext
            )) ?? false
            if complete { continue }
            guard hasRoutineStartedToday(routine, now: now, calendar: calendar) else { continue }
            guard let end = RoutineDeadline.endTimeToday(for: routine, now: now, calendar: calendar),
                  now >= end else { continue }
            missedDeadlineToday = true
            break
        }

        if missedDeadlineToday {
            DeadlineGraceStore.recordMissForTodayIfNeeded(dayKey: dayKey)
        }
    }
}
