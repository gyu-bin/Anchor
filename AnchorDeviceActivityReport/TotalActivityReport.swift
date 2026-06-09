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
        periodLabel: String,
        multiDay: Bool = false
    ) async -> ScreenTimeSummary {
        var perSource: [TimeInterval] = []
        var appSeconds: [Application: TimeInterval] = [:]

        for await activityData in data {
            var segmentDurations: [TimeInterval] = []
            for await segment in activityData.activitySegments {
                segmentDurations.append(segment.totalActivityDuration)
                for await category in segment.categories {
                    for await app in category.applications {
                        appSeconds[app.application, default: 0] += app.totalActivityDuration
                    }
                }
            }
            guard !segmentDurations.isEmpty else { continue }

            if !multiDay {
                // 오늘: 여러 소스 중복 제거 (가장 큰 값 사용)
                let sum = segmentDurations.reduce(0, +)
                let peak = segmentDurations.max() ?? 0
                let contribution = (segmentDurations.count == 1 || sum <= peak * 1.6) ? sum : peak
                perSource.append(contribution)
            }
        }

        // 주간: data가 날짜별로 쪼개져 오므로 perSource.max()가 최대 하루값이 됨.
        // 앱별 누적합을 쓰면 날짜 구조 무관하게 주간 전체 시간이 됨.
        let totalSeconds: TimeInterval
        if multiDay {
            totalSeconds = appSeconds.values.reduce(0, +)
        } else {
            totalSeconds = perSource.max() ?? 0
        }

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

@MainActor
struct TodayActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalToday
    let content: (ScreenTimeSummary) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ScreenTimeSummary {
        await ScreenTimeAggregation.buildSummary(from: data, periodLabel: "오늘")
    }
}

@MainActor
struct WeekActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalWeek
    let content: (ScreenTimeSummary) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ScreenTimeSummary {
        await ScreenTimeAggregation.buildSummary(from: data, periodLabel: "이번 주", multiDay: true)
    }
}
