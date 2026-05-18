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
    static func activityNames(for routine: Routine) -> [DeviceActivityName] {
        switch routine.scheduleKind {
        case .daily, .once:
            return [DeviceActivityName(routine.id.uuidString)]
        case .weekdays:
            let weekdays = RoutineSchedule.activeWeekdays(for: routine)
            return weekdays.map { DeviceActivityName("\(routine.id.uuidString)-\($0)") }
        }
    }

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
            let names = activityNames(for: routine)
            center.stopMonitoring(names)

            guard RoutineSchedule.isActive(routine, on: Date(), calendar: calendar) else {
                continue
            }

            let complete = (try? routineIsFullyCompleteToday(
                routine,
                dayStart: dayStart,
                calendar: calendar,
                modelContext: modelContext
            )) ?? false

            let selection = ShieldManager.decodeSelection(routine.shieldSelectionData)
            let selectionData = (try? ShieldManager.encodeSelection(selection)) ?? Data()
            let start = calendar.dateComponents([.hour, .minute], from: routine.startTime)

            if !complete {
                scheduleItems.append(
                    ScheduledRoutineShield(
                        routineId: routine.id,
                        startHour: start.hour ?? 0,
                        startMinute: start.minute ?? 0,
                        isComplete: false,
                        selectionData: selectionData
                    )
                )
            }

            if complete { continue }

            if ShieldManager.hasRoutineStartedToday(routine, calendar: calendar) {
                pendingMerge.applicationTokens.formUnion(selection.applicationTokens)
                pendingMerge.webDomainTokens.formUnion(selection.webDomainTokens)
            }

            switch routine.scheduleKind {
            case .daily, .once:
                let schedule = DeviceActivitySchedule(
                    intervalStart: DateComponents(hour: start.hour, minute: start.minute),
                    intervalEnd: DateComponents(hour: 23, minute: 59),
                    repeats: routine.scheduleKind == .daily
                )
                startMonitoring(center: center, name: names[0], schedule: schedule)
            case .weekdays:
                let weekdays = RoutineSchedule.activeWeekdays(for: routine)
                for (index, weekday) in weekdays.enumerated() {
                    let schedule = DeviceActivitySchedule(
                        intervalStart: DateComponents(
                            hour: start.hour,
                            minute: start.minute,
                            weekday: weekday
                        ),
                        intervalEnd: DateComponents(hour: 23, minute: 59, weekday: weekday),
                        repeats: true
                    )
                    guard index < names.count else { continue }
                    startMonitoring(center: center, name: names[index], schedule: schedule)
                }
            }
        }

        SharedShieldStore.saveMergedSelection(pendingMerge)
        SharedShieldStore.saveSchedule(scheduleItems)
    }

    static func stopAllMonitoring(routines: [Routine]) {
        guard !routines.isEmpty else { return }
        let center = DeviceActivityCenter()
        let names = routines.flatMap { activityNames(for: $0) }
        center.stopMonitoring(names)
    }

    private static func startMonitoring(
        center: DeviceActivityCenter,
        name: DeviceActivityName,
        schedule: DeviceActivitySchedule
    ) {
        do {
            try center.startMonitoring(name, during: schedule)
        } catch {
            // 시뮬레이터·권한 미비 시 무시
        }
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
