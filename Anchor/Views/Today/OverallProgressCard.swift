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
    let blockSummary: BlockedShieldSummary
    let isActivelyLocking: Bool

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
                        Text(isActivelyLocking ? AppCopy.Today.lockActive : AppCopy.Today.lockScheduled)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(isActivelyLocking ? Color.anchorWarning(scheme) : Color.anchorSub(scheme))

                        BlockedShieldDisplay(summary: blockSummary, maxApps: 6, maxWebs: 6)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(AnchorLayout.cardPadding)
        }
    }
}
