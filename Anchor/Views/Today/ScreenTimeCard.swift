//
//  ScreenTimeCard.swift
//  Anchor
//

import DeviceActivity
import SwiftUI

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

struct ScreenTimeCard: View {
    @Environment(\.colorScheme) private var scheme

    private var todayFilter: DeviceActivityFilter {
        let cal = Calendar.current
        let now = Date()
        let interval = cal.dateInterval(of: .day, for: now)
            ?? DateInterval(start: now, duration: 86400)
        return DeviceActivityFilter(
            segment: .daily(during: interval),
            users: .all,
            devices: .init([.iPhone])
        )
    }

    var body: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "hourglass")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.anchorAccent(scheme))
                    Text("스크린타임")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.anchorSub(scheme))
                }
                .padding(.horizontal, AnchorLayout.cardPadding)
                .padding(.top, AnchorLayout.cardPadding)
                .padding(.bottom, 4)

                DeviceActivityReport(.totalActivity, filter: todayFilter)
            }
        }
    }
}
