//
//  Routine+ModelAccess.swift
//  Anchor
//

import Foundation
import SwiftData

extension Routine {
    /// 컨텍스트에서 분리된 뒤 `blockedWebs`를 읽으면 SwiftData가 크래시할 수 있어, 필요 시 ID로 다시 조회합니다.
    func resolvedBlockedWebs(in context: ModelContext) -> [String] {
        guard modelContext != nil else {
            return Self.fetchBlockedWebs(id: id, in: context)
        }
        return blockedWebs
    }

    private static func fetchBlockedWebs(id: UUID, in context: ModelContext) -> [String] {
        var descriptor = FetchDescriptor<Routine>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor).first)?.blockedWebs ?? []
    }
}
