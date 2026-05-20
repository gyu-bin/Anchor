//
//  AnchorDeviceActivityReport.swift
//  AnchorDeviceActivityReport
//
//  Created by 문규빈 on 5/20/26.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct AnchorDeviceActivityReport: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Create a report for each DeviceActivityReport.Context that your app supports.
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
        // Add more reports here...
    }
}
