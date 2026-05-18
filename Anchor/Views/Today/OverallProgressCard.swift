//
//  OverallProgressCard.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct OverallProgressCard: View {
    @Environment(\.colorScheme) private var scheme

    let routines: [Routine]
    let logs: [DailyLog]
    /// 지금 실제로 잠금 중인 앱·웹만 포함 (시작 전 루틴의 예정 차단은 제외).
    let blockSummary: BlockedShieldSummary

    private var routinesWithItems: [Routine] {
        routines.filter { !$0.items.isEmpty }
    }

    private var completedRoutines: Int {
        let ids = Set(routinesWithItems.map(\.id))
        return logs.filter { ids.contains($0.routineId) && $0.isFullyCompleted }.count
    }

    private var totalRoutines: Int {
        routinesWithItems.count
    }

    private var progress: Double {
        totalRoutines == 0 ? 0 : Double(completedRoutines) / Double(totalRoutines)
    }

    var body: some View {
        AnchorCard {
            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    ProgressRingView(progress: progress, lineWidth: 6)
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.anchorText(scheme))
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 6) {
                    Text(AppCopy.Today.progressTitle(completed: completedRoutines, total: totalRoutines))
                        .font(AnchorTypography.cardTitle(scheme))
                        .foregroundStyle(Color.anchorText(scheme))

                    Text(AppCopy.Today.progressSubtitle(completed: completedRoutines, total: totalRoutines))
                        .font(.subheadline)
                        .foregroundStyle(Color.anchorSub(scheme))

                    if completedRoutines < totalRoutines, blockSummary.hasAnyBlock {
                        Text(AppCopy.Today.lockActive)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.anchorWarning(scheme))

                        BlockedShieldDisplay(summary: blockSummary, maxApps: 6, maxWebs: 6)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(AnchorLayout.cardPadding)
        }
    }
}
