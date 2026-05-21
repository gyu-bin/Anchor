//
//  RoutineDeletion.swift
//  Anchor
//

import Foundation
import SwiftData

/// 루틴 삭제 시 연관 `DailyLog`를 먼저 제거해 SwiftData fault 크래시를 방지합니다.
@MainActor
enum RoutineDeletion {
    static func delete(_ routine: Routine, context: ModelContext) {
        let routineId = routine.id
        purgeLogs(for: routineId, context: context)
        context.delete(routine)
        try? context.save()
        context.processPendingChanges()
    }

    static func purgeLogs(for routineId: UUID, context: ModelContext) {
        let rid = routineId
        let fd = FetchDescriptor<DailyLog>(
            predicate: #Predicate<DailyLog> { log in
                log.routineId == rid
            }
        )
        guard let logs = try? context.fetch(fd) else { return }
        for log in logs {
            context.delete(log)
        }
        if context.hasChanges {
            try? context.save()
            context.processPendingChanges()
        }
    }
}
