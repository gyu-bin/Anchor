//
//  WidgetPendingItem.swift
//  AnchorWidget
//

import Foundation

struct WidgetPendingItem: Codable, Equatable, Identifiable {
    var id: String { "\(routineName)|\(itemName)" }
    let itemName: String
    let routineName: String
    let icon: String
}

enum WidgetPendingItemCodec {
    static let storageKey = "widget.remainingItemsJSON"

    static func decode(from suite: UserDefaults?) -> [WidgetPendingItem] {
        let data = suite?.data(forKey: storageKey)
        guard let data, !data.isEmpty else { return [] }
        return (try? JSONDecoder().decode([WidgetPendingItem].self, from: data)) ?? []
    }
}
