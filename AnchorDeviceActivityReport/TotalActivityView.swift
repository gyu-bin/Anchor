//
//  TotalActivityView.swift
//  AnchorDeviceActivityReport
//

import FamilyControls
import ManagedSettings
import SwiftUI

struct TotalActivityView: View {
    let totalActivity: ScreenTimeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(totalActivity.formattedTotal)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text("전체 · \(totalActivity.periodLabel)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }

            if !totalActivity.apps.isEmpty {
                Text("앱별")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    ForEach(totalActivity.apps) { row in
                        HStack(spacing: 10) {
                            Label(row.token)
                                .font(.subheadline)
                                .lineLimit(1)

                            Spacer(minLength: 8)

                            Text(ScreenTimeSummary.format(minutes: row.minutes))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    TotalActivityView(
        totalActivity: ScreenTimeSummary(
            periodLabel: "오늘",
            totalMinutes: 154,
            apps: []
        )
    )
}
