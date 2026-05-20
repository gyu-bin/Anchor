
//
//  TempUnlockLiveActivity.swift
//  AnchorWidget
//

import ActivityKit
import SwiftUI
import WidgetKit

struct TempUnlockLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TempUnlockAttributes.self) { context in
            // 잠금화면 / 알림센터에 보이는 뷰
            HStack(spacing: 12) {
                Image(systemName: "lock.open.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("앱 잠금 임시 해제 중")
                        .font(.subheadline.weight(.semibold))
                    Text(context.state.expiresAt, style: .timer)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Spacer()

                Text("후 잠금")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("잠금 해제", systemImage: "lock.open.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.expiresAt, style: .timer)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.primary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("타이머가 끝나면 자동으로 앱이 잠겨요")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "lock.open.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                Text(context.state.expiresAt, style: .timer)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.primary)
            } minimal: {
                Image(systemName: "lock.open.fill")
                    .foregroundStyle(.orange)
            }
        }
    }
}
