//
//  QuickLockLiveActivity.swift
//  AnchorWidget
//

import ActivityKit
import SwiftUI
import WidgetKit

struct QuickLockLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: QuickLockAttributes.self) { context in
            // 잠금화면 / 알림센터
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "bolt.shield.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("빠른 잠금 중 · 앱 \(context.state.appCount)개")
                        .font(.subheadline.weight(.semibold))
                    Text(context.state.expiresAt, style: .timer)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Spacer()

                Text("후 해제")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        Text("앱 \(context.state.appCount)개")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.expiresAt, style: .timer)
                        .font(.headline.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("타이머가 끝나면 자동으로 앱 잠금이 해제돼요")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "bolt.shield.fill")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                Text(context.state.expiresAt, style: .timer)
                    .font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: "bolt.shield.fill")
                    .foregroundStyle(.blue)
            }
        }
    }
}
