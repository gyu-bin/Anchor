//
//  AnchorDeviceActivityReport.swift
//  AnchorDeviceActivityReport
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct AnchorDeviceActivityReport: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TodayActivityReport { summary in
            TotalActivityView(totalActivity: summary)
        }
        WeekActivityReport { summary in
            TotalActivityView(totalActivity: summary)
        }
    }
}
