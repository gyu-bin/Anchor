//
//  ScreenTimeReportSection.swift
//  Anchor
//

import DeviceActivity
import FamilyControls
import SwiftUI

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

enum ScreenTimePeriod: String, CaseIterable, Identifiable {
    case today
    case thisWeek

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return AppCopy.Settings.screenTimeToday
        case .thisWeek: return AppCopy.Settings.screenTimeThisWeek
        }
    }
}



/// 설정·기타 화면에 넣는 스크린타임 리포트 (전체·앱별, 오늘·이번 주).
struct ScreenTimeReportSection: View {
    @Environment(\.colorScheme) private var scheme

    let authorizationStatus: AuthorizationStatus
    var onRequestAuthorization: () -> Void

    @State private var period: ScreenTimePeriod = .today

    private func filter(for period: ScreenTimePeriod) -> DeviceActivityFilter {
        let cal = Calendar.current
        let now = Date()
        let interval: DateInterval
        switch period {
        case .today:
            interval = cal.dateInterval(of: .day, for: now)
                ?? DateInterval(start: now, duration: 86_400)
        case .thisWeek:
            interval = cal.dateInterval(of: .weekOfYear, for: now)
                ?? DateInterval(start: now, duration: 86_400 * 7)
        }
        return DeviceActivityFilter(
            segment: .daily(during: interval),
            users: .all,
            devices: .init([.iPhone])
        )
    }

    private var reportContext: DeviceActivityReport.Context {
        .totalActivity
    }

    var body: some View {
        Group {
            if authorizationStatus == .approved {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("기간", selection: $period) {
                        ForEach(ScreenTimePeriod.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AnchorLayout.cardPadding)
                    .padding(.top, 4)

                    DeviceActivityReport(reportContext, filter: filter(for: period))
                        .frame(minHeight: period == .today ? 120 : 160)
                        .id(period)

                    Text(AppCopy.Settings.screenTimeFootnote)
                        .font(.caption2)
                        .foregroundStyle(Color.anchorSub(scheme).opacity(0.85))
                        .lineSpacing(3)
                        .padding(.horizontal, AnchorLayout.cardPadding)
                        .padding(.bottom, 8)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppCopy.Settings.screenTimeNeedsPermission)
                        .font(.subheadline)
                        .foregroundStyle(Color.anchorSub(scheme))
                        .lineSpacing(4)

                    Button(AppCopy.Onboarding.screenTimeAllow, action: onRequestAuthorization)
                        .buttonStyle(AnchorTextButtonStyle())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AnchorLayout.cardPadding)
                .padding(.vertical, 14)
            }
        }
    }
}
