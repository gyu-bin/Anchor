//
//  DeviceActivityScheduleManager.swift
//  Anchor
//

import DeviceActivity
import FamilyControls
import Foundation
import SwiftData

/// 루틴 시작 시각에 Device Activity 모니터를 등록하고, App Group에 잠금 데이터를 동기화합니다.
@MainActor
enum DeviceActivityScheduleManager {
    static func sync(modelContext: ModelContext) async {
        guard ShieldManager.authorizationStatus() == .approved else {
            if let routines = try? modelContext.fetch(FetchDescriptor<Routine>()) {
                stopAllMonitoring(routines: routines)
            }
            SharedShieldStore.clearAll()
            return
        }

        guard let routines = try? modelContext.fetch(FetchDescriptor<Routine>()) else { return }

        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: Date())
        let center = DeviceActivityCenter()

        var pendingMerge = FamilyActivitySelection()
        var scheduleItems: [ScheduledRoutineShield] = []

        for routine in routines where !routine.items.isEmpty {
            let activityName = DeviceActivityName(routine.id.uuidString)
            let complete = (try? routineIsFullyCompleteToday(
                routine,
                dayStart: dayStart,
                calendar: calendar,
                modelContext: modelContext
            )) ?? false

            let selection = ShieldManager.decodeSelection(routine.shieldSelectionData)
            let selectionData = (try? ShieldManager.encodeSelection(selection)) ?? Data()
            let start = calendar.dateComponents([.hour, .minute], from: routine.startTime)

            scheduleItems.append(
                ScheduledRoutineShield(
                    routineId: routine.id,
                    startHour: start.hour ?? 0,
                    startMinute: start.minute ?? 0,
                    isComplete: complete,
                    selectionData: selectionData
                )
            )

            if complete {
                center.stopMonitoring([activityName])
                continue
            }

            if ShieldManager.hasRoutineStartedToday(routine, calendar: calendar) {
                pendingMerge.applicationTokens.formUnion(selection.applicationTokens)
                pendingMerge.webDomainTokens.formUnion(selection.webDomainTokens)
            }

            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: start.hour, minute: start.minute),
                intervalEnd: DateComponents(hour: 23, minute: 59),
                repeats: true
            )

            center.stopMonitoring([activityName])
            do {
                try center.startMonitoring(activityName, during: schedule)
            } catch {
                // 시뮬레이터·권한 미비 시 무시
            }
        }

        SharedShieldStore.saveMergedSelection(pendingMerge)
        SharedShieldStore.saveSchedule(scheduleItems)
    }

    static func stopAllMonitoring(routines: [Routine]) {
        guard !routines.isEmpty else { return }
        let center = DeviceActivityCenter()
        let names = routines.map { DeviceActivityName($0.id.uuidString) }
        center.stopMonitoring(names)
    }

    private static func routineIsFullyCompleteToday(
        _ routine: Routine,
        dayStart: Date,
        calendar: Calendar,
        modelContext: ModelContext
    ) throws -> Bool {
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
