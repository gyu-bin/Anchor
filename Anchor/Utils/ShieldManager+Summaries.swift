//
//  ShieldManager+Summaries.swift
//  Anchor
//

import FamilyControls
import Foundation
import ManagedSettings
import SwiftData

// MARK: - UI·집계용 차단 요약

extension ShieldManager {
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
        let keepShield = RoutineDeadline.shouldKeepShield(
            routine: routine,
            isComplete: complete,
            now: Date(),
            calendar: calendar
        )
        let apps = started && keepShield ? selection.applicationTokens : []
        let webs = started && keepShield ? selection.webDomainTokens : []

        return BlockedShieldSummary(
            appTokens: Array(apps).stableSorted(),
            webTokens: Array(webs).stableSorted(),
            webDomains: started && keepShield ? routine.resolvedBlockedWebs(in: modelContext) : []
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
            appTokens: Array(selection.applicationTokens).stableSorted(),
            webTokens: Array(selection.webDomainTokens).stableSorted(),
            webDomains: routine.resolvedBlockedWebs(in: modelContext)
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
            appTokens: apps.stableSorted(),
            webTokens: webs.stableSorted(),
            webDomains: domains
        )
    }

    /// 즉시 잠금(빠른 잠금)에 선택된 앱·웹 — 오늘 탭 표시용.
    static func quickLockDisplaySummary() -> BlockedShieldSummary {
        guard QuickLockStore.isActive else {
            return BlockedShieldSummary(appTokens: [], webTokens: [], webDomains: [])
        }
        let selection = decodeSelection(QuickLockStore.selectionData)
        return BlockedShieldSummary(
            appTokens: Array(selection.applicationTokens).stableSorted(),
            webTokens: Array(selection.webDomainTokens).stableSorted(),
            webDomains: []
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
            appTokens: apps.stableSorted(),
            webTokens: webs.stableSorted(),
            webDomains: domains
        )
    }

    static func activeBlockedApplicationTokens(for routine: Routine, modelContext: ModelContext) -> [ApplicationToken] {
        blockedSummary(for: routine, modelContext: modelContext).appTokens
    }

    static func activeBlockedApplicationTokens(
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
            guard RoutineDeadline.shouldKeepShield(
                routine: routine,
                isComplete: complete,
                now: Date(),
                calendar: calendar
            ) else { continue }
            tokens.formUnion(decodeSelection(routine.shieldSelectionData).applicationTokens)
        }
        return tokens.stableSorted()
    }

    static func activeBlockedWebDomainTokens(
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
            guard RoutineDeadline.shouldKeepShield(
                routine: routine,
                isComplete: complete,
                now: Date(),
                calendar: calendar
            ) else { continue }
            tokens.formUnion(decodeSelection(routine.shieldSelectionData).webDomainTokens)
        }
        return tokens.stableSorted()
    }

    static func activeBlockedWebDomainStrings(
        routines: [Routine],
        dayStart: Date,
        calendar: Calendar,
        modelContext: ModelContext
    ) -> [String] {
        var domains: [String] = []
        for routine in routines where RoutineSchedule.isActive(routine, on: Date(), calendar: calendar) && !routine.items.isEmpty {
            let complete = (try? routineIsFullyCompleteToday(
                routine,
                dayStart: dayStart,
                calendar: calendar,
                modelContext: modelContext
            )) ?? false
            if complete { continue }
            guard hasRoutineStartedToday(routine, calendar: calendar) else { continue }
            guard RoutineDeadline.shouldKeepShield(
                routine: routine,
                isComplete: complete,
                now: Date(),
                calendar: calendar
            ) else { continue }
            for domain in routine.resolvedBlockedWebs(in: modelContext) where !domains.contains(domain) {
                domains.append(domain)
            }
        }
        return domains
    }

    static func routineIsFullyCompleteToday(
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
