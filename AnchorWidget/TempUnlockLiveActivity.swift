
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
            tempUnlockBanner(context: context)
                .activityBackgroundTint(Color.black.opacity(0.75))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.open.fill")
                            .foregroundStyle(.orange)
                        Text("10분 해제")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.expiresAt, style: .timer)
                        .font(.headline.monospacedDigit())
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("끝나면 다시 앱이 잠겨요")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "lock.open.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                Text(context.state.expiresAt, style: .timer)
                    .font(.caption2.monospacedDigit())
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "lock.open.fill")
                    .foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private func tempUnlockBanner(context: ActivityViewContext<TempUnlockAttributes>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.open.fill")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("앱 잠금 임시 해제")
                    .font(.subheadline.weight(.semibold))
                Text(context.state.expiresAt, style: .timer)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
