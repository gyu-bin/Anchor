//
//  ScreenTimeSummary.swift
//  AnchorDeviceActivityReport
//

import Foundation

struct ScreenTimeSummary: Sendable {
    let totalMinutes: Int

    var formatted: String {
        guard totalMinutes > 0 else { return "0분" }
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        switch (h, m) {
        case (0, _): return "\(m)분"
        case (_, 0): return "\(h)시간"
        default:     return "\(h)시간 \(m)분"
        }
    }
}
