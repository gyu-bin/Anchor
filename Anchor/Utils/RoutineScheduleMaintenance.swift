//
//  RoutineScheduleMaintenance.swift
//  Anchor
//

import Foundation
import SwiftData

/// 종료일이 지난 루틴 → 템플릿 저장 후 삭제
@MainActor
enum RoutineScheduleMaintenance {
    static func run(modelContext: ModelContext, calendar: Calendar = .current) {
        guard let routines = try? modelContext.fetch(FetchDescriptor<Routine>()) else { return }
        var changed = false

        for routine in routines {
            guard RoutineSchedule.isExpired(routine, calendar: calendar) else { continue }
            guard RoutineSchedule.effectiveEndDay(for: routine, calendar: calendar) != nil else { continue }

            RoutineTemplateStore.save(from: routine, context: modelContext)
            RoutineDeletion.delete(routine, context: modelContext)
            changed = true
        }

        if changed {
            try? modelContext.save()
            RoutineSync.afterMutation(modelContext: modelContext)
        }
    }
}
