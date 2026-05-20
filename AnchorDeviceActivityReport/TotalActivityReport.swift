//
//  TotalActivityReport.swift
//  AnchorDeviceActivityReport
//

import DeviceActivity
import ExtensionKit
import SwiftUI

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (ScreenTimeSummary) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ScreenTimeSummary {
        let totalSeconds = await data.flatMap { $0.activitySegments }.reduce(0) {
            $0 + $1.totalActivityDuration
        }
        return ScreenTimeSummary(totalMinutes: Int(totalSeconds / 60))
    }
}
