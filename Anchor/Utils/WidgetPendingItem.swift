//
//  WidgetPendingItem.swift
//  Anchor
//

import Foundation

/// 위젯에 표시할 미완료 할 일 (App Group JSON)
struct WidgetPendingItem: Codable, Equatable, Identifiable {
    var id: String { "\(routineName)|\(itemName)" }
    let itemName: String
    let routineName: String
    let icon: String
}

enum WidgetPendingItemCodec {
    static let storageKey = "widget.remainingItemsJSON"

    static func encode(_ items: [WidgetPendingItem]) -> Data? {
        try? JSONEncoder().encode(items)
    }

    static func decode(from data: Data?) -> [WidgetPendingItem] {
        guard let data, !data.isEmpty else { return [] }
        return (try? JSONDecoder().decode([WidgetPendingItem].self, from: data)) ?? []
    }
}
