//
//  Extensions.swift
//  Anchor
//

import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Date {
    func startOfDay(in calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }

    func addingDays(_ n: Int, calendar: Calendar = .current) -> Date? {
        calendar.date(byAdding: .day, value: n, to: self)
    }
}

extension Notification.Name {
    static let anchorOpenTodayTab = Notification.Name("anchorOpenTodayTab")
    static let anchorOpenHistoryTab = Notification.Name("anchorOpenHistoryTab")
    static let anchorRefreshShield = Notification.Name("anchorRefreshShield")
    static let anchorCompleteNextItem = Notification.Name("anchorCompleteNextItem")
    static let anchorRegisterRemotePush = Notification.Name("anchorRegisterRemotePush")
}
