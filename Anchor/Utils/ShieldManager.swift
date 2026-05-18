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

        let apps = activeBlockedApplicationTokens(
            routines: routines,
            dayStart: dayStart,
            calendar: calendar,
            modelContext: modelContext
        )
        let webs = activeBlockedWebDomainTokens(
            routines: routines,
            dayStart: dayStart,
            calendar: calendar,
            modelContext: modelContext
        )

        if apps.isEmpty && webs.isEmpty {
            settings.clearAllSettings()
        } else {
            settings.shield.applications = apps.isEmpty ? nil : Set(apps)
            settings.shield.webDomains = webs.isEmpty ? nil : Set(webs)
        }

        await DeviceActivityScheduleManager.sync(modelContext: modelContext)
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

    /// 지금 실제로 잠금이 걸려야 하는지(시작 후 + 미완료).
    static func isActivelyLocking(routine: Routine, modelContext: ModelContext) -> Bool {
        let calendar = Calendar.current
        guard RoutineSchedule.isActive(routine, on: Date(), calendar: calendar) else { return false }
        let dayStart = calendar.startOfDay(for: Date())
        let complete = (try? routineIsFullyCompleteToday(
            routine,
            dayStart: dayStart,
            calendar: calendar,
            modelContext: modelContext
        )) ?? false
        if complete || routine.items.isEmpty { return false }
        guard hasRoutineStartedToday(routine, calendar: calendar) else { return false }
        let summary = blockedSummary(for: routine, modelContext: modelContext)
        return summary.hasAnyBlock
    }

    static func activeBlockedApplicationTokens(modelContext: ModelContext) -> [ApplicationToken] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: Date())
        guard let routines = try? modelContext.fetch(FetchDescriptor<Routine>()) else { return [] }
        return activeBlockedApplicationTokens(
            routines: routines,
            dayStart: dayStart,
            calendar: calendar,
            modelContext: modelContext
        )
    }

    static func activeBlockedWebDomainTokens(modelContext: ModelContext) -> [WebDomainToken] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: Date())
        guard let routines = try? modelContext.fetch(FetchDescriptor<Routine>()) else { return [] }
        return activeBlockedWebDomainTokens(
            routines: routines,
            dayStart: dayStart,
            calendar: calendar,
            modelContext: modelContext
        )
    }

    static func blockedSummary(for routine: Routine, modelContext: ModelContext) -> BlockedShieldSummary {
        let calendar = Calendar.current
        guard RoutineSchedule.isActive(routine, on: Date(), calendar: calendar) else {
            return BlockedShieldSummary(appTokens: [], webTokens: [], webDomains: [])
        }
        let dayStart = calendar.startOfDay(for: Date())
        let complete = (try? routineIsFullyCompleteToday(
            routine,
            dayStart: dayStart,
            calendar: calendar,
            modelContext: modelContext
        )) ?? false

        if complete || routine.items.isEmpty {
            return BlockedShieldSummary(appTokens: [], webTokens: [], webDomains: [])
        }

        let selection = decodeSelection(routine.shieldSelectionData)
        let started = hasRoutineStartedToday(routine, calendar: calendar)
        let apps = started ? selection.applicationTokens : []
        let webs = started ? selection.webDomainTokens : []

        return BlockedShieldSummary(
            appTokens: Array(apps).sorted { String(describing: $0) < String(describing: $1) },
            webTokens: Array(webs).sorted { String(describing: $0) < String(describing: $1) },
            webDomains: started ? routine.blockedWebs : []
        )
    }

    /// 오늘 탭 표시용 — 시작 전에도 설정된 차단 목록을 보여줍니다.
    static func displaySummary(for routine: Routine, modelContext: ModelContext) -> BlockedShieldSummary {
        let calendar = Calendar.current
        guard RoutineSchedule.isActive(routine, on: Date(), calendar: calendar) else {
            return BlockedShieldSummary(appTokens: [], webTokens: [], webDomains: [])
        }
        let dayStart = calendar.startOfDay(for: Date())
        let complete = (try? routineIsFullyCompleteToday(
            routine,
            dayStart: dayStart,
            calendar: calendar,
            modelContext: modelContext
        )) ?? false
        if complete || routine.items.isEmpty {
            return BlockedShieldSummary(appTokens: [], webTokens: [], webDomains: [])
        }
        let selection = decodeSelection(routine.shieldSelectionData)
        return BlockedShieldSummary(
            appTokens: Array(selection.applicationTokens).sorted { String(describing: $0) < String(describing: $1) },
            webTokens: Array(selection.webDomainTokens).sorted { String(describing: $0) < String(describing: $1) },
            webDomains: routine.blockedWebs
        )
    }

    static func aggregatedDisplaySummary(routines: [Routine], modelContext: ModelContext) -> BlockedShieldSummary {
        var apps = Set<ApplicationToken>()
        var webs = Set<WebDomainToken>()
        var domains: [String] = []

        for routine in routines where RoutineSchedule.isVisibleToday(routine) {
            let summary = displaySummary(for: routine, modelContext: modelContext)
            apps.formUnion(summary.appTokens)
            webs.formUnion(summary.webTokens)
            for d in summary.webDomains where !domains.contains(d) {
                domains.append(d)
            }
        }

        return BlockedShieldSummary(
            appTokens: apps.sorted { String(describing: $0) < String(describing: $1) },
            webTokens: webs.sorted { String(describing: $0) < String(describing: $1) },
            webDomains: domains
        )
    }

    static func aggregatedBlockedSummary(
        routines: [Routine],
        modelContext: ModelContext
    ) -> BlockedShieldSummary {
        var apps = Set<ApplicationToken>()
        var webs = Set<WebDomainToken>()
        var domains: [String] = []

        for routine in routines where RoutineSchedule.isVisibleToday(routine) {
            let summary = blockedSummary(for: routine, modelContext: modelContext)
            apps.formUnion(summary.appTokens)
            webs.formUnion(summary.webTokens)
            for d in summary.webDomains where !domains.contains(d) {
                domains.append(d)
            }
        }

        return BlockedShieldSummary(
            appTokens: apps.sorted { String(describing: $0) < String(describing: $1) },
            webTokens: webs.sorted { String(describing: $0) < String(describing: $1) },
            webDomains: domains
        )
    }

    static func activeBlockedApplicationTokens(for routine: Routine, modelContext: ModelContext) -> [ApplicationToken] {
        blockedSummary(for: routine, modelContext: modelContext).appTokens
    }

    private static func activeBlockedApplicationTokens(
        routines: [Routine],
        dayStart: Date,
        calendar: Calendar,
        modelContext: ModelContext
    ) -> [ApplicationToken] {
        var tokens = Set<ApplicationToken>()
        for routine in routines where RoutineSchedule.isActive(routine, on: Date(), calendar: calendar) && !routine.items.isEmpty {
            let complete = (try? routineIsFullyCompleteToday(
                routine,
                dayStart: dayStart,
                calendar: calendar,
                modelContext: modelContext
            )) ?? false
            if complete { continue }
            guard hasRoutineStartedToday(routine, calendar: calendar) else { continue }
            tokens.formUnion(decodeSelection(routine.shieldSelectionData).applicationTokens)
        }
        return tokens.sorted { String(describing: $0) < String(describing: $1) }
    }

    private static func activeBlockedWebDomainTokens(
        routines: [Routine],
        dayStart: Date,
        calendar: Calendar,
        modelContext: ModelContext
    ) -> [WebDomainToken] {
        var tokens = Set<WebDomainToken>()
        for routine in routines where RoutineSchedule.isActive(routine, on: Date(), calendar: calendar) && !routine.items.isEmpty {
            let complete = (try? routineIsFullyCompleteToday(
                routine,
                dayStart: dayStart,
                calendar: calendar,
                modelContext: modelContext
            )) ?? false
            if complete { continue }
            guard hasRoutineStartedToday(routine, calendar: calendar) else { continue }
            tokens.formUnion(decodeSelection(routine.shieldSelectionData).webDomainTokens)
        }
        return tokens.sorted { String(describing: $0) < String(describing: $1) }
    }

    private static func routineIsFullyCompleteToday(
        _ routine: Routine,
        dayStart: Date,
        calendar: Calendar,
        modelContext: ModelContext
    ) throws -> Bool {
        if RestDayStore.isRestDay(dayStart, calendar: calendar) {
            return true
        }
        let rid = routine.id
        var fd = FetchDescriptor<DailyLog>(
            predicate: #Predicate { log in
                log.routineId == rid
            }
        )
        fd.fetchLimit = 200
        let logs = try modelContext.fetch(fd)
        guard let log = logs.first(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) else {
            return false
        }
        return log.isFullyCompleted
    }
}
