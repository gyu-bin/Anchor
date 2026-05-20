//
//  TotalActivityView.swift
//  AnchorDeviceActivityReport
//

import SwiftUI

struct TotalActivityView: View {
    let totalActivity: ScreenTimeSummary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(totalActivity.formatted)
                .font(.system(.title3, design: .rounded, weight: .bold))
            Text("오늘 사용")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TotalActivityView(totalActivity: ScreenTimeSummary(totalMinutes: 154))
}
