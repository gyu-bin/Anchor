//
//  TotalActivityReport.swift
//  AnchorDeviceActivityReport
//

import DeviceActivity
import ExtensionKit
import ManagedSettings
import SwiftUI

extension DeviceActivityReport.Context {
    static let totalToday = Self("Total Activity Today")
    static let totalWeek = Self("Total Activity This Week")
}

struct AppScreenTimeRow: Identifiable {
    let token: ApplicationToken
    let displayName: String?
    let minutes: Int

    var id: ApplicationToken { token }
}

struct ScreenTimeSummary {
    let periodLabel: String
    let totalMinutes: Int
    let apps: [AppScreenTimeRow]

    var formattedTotal: String {
        Self.format(minutes: totalMinutes)
    }

    static func format(minutes: Int) -> String {
        guard minutes > 0 else { return "0분" }
        let h = minutes / 60
        let m = minutes % 60
        switch (h, m) {
        case (0, _): return "\(m)분"
        case (_, 0): return "\(h)시간"
        default: return "\(h)시간 \(m)분"
        }
    }
}

private enum ScreenTimeAggregation {
    static func buildSummary(
        from data: DeviceActivityResults<DeviceActivityData>,
        periodLabel: String
    ) async -> ScreenTimeSummary {
        var perSource: [TimeInterval] = []
        var appSeconds: [Application: TimeInterval] = [:]

        for await activityData in data {
            var durations: [TimeInterval] = []
            for await segment in activityData.activitySegments {
                durations.append(segment.totalActivityDuration)
                for await category in segment.categories {
                    for await app in category.applications {
                        appSeconds[app.application, default: 0] += app.totalActivityDuration
                    }
                }
            }
            guard !durations.isEmpty else { continue }

            let sum = durations.reduce(0, +)
            let peak = durations.max() ?? 0
            let contribution: TimeInterval
            if durations.count == 1 {
                contribution = peak
            } else if sum > peak * 1.6 {
                contribution = peak
            } else {
                contribution = sum
            }
            perSource.append(contribution)
        }

        let totalSeconds = perSource.max() ?? 0
        let apps = appSeconds
            .compactMap { application, seconds -> AppScreenTimeRow? in
                guard let token = application.token else { return nil }
                let minutes = max(0, Int(seconds / 60))
                guard minutes > 0 else { return nil }
                return AppScreenTimeRow(
                    token: token,
                    displayName: application.localizedDisplayName,
                    minutes: minutes
                )
            }
            .sorted { $0.minutes > $1.minutes }
            .prefix(8)
            .map(\.self)

        return ScreenTimeSummary(
            periodLabel: periodLabel,
            totalMinutes: max(0, Int(totalSeconds / 60)),
            apps: apps
        )
    }
}

struct TodayActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalToday
    let content: (ScreenTimeSummary) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ScreenTimeSummary {
        await ScreenTimeAggregation.buildSummary(from: data, periodLabel: "오늘")
    }
}

struct WeekActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalWeek
    let content: (ScreenTimeSummary) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ScreenTimeSummary {
        await ScreenTimeAggregation.buildSummary(from: data, periodLabel: "이번 주")
    }
}
