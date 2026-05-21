//
//  OverallProgressCard.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct OverallProgressCard: View {
    @Environment(\.colorScheme) private var scheme

    let routines: [Routine]
    let logSnapshots: [TodayLogSnapshot]
    let lockSnapshot: TodayProgressSnapshot
    /// 지금 실제로 잠금 중인 앱·웹만 포함 (시작 전 루틴의 예정 차단은 제외).
    let blockSummary: BlockedShieldSummary

    private var routinesWithItems: [Routine] {
        routines.filter { !$0.items.isEmpty }
    }

    private var completedRoutines: Int {
        routinesWithItems.filter { routine in
            guard let snap = logSnapshots.first(where: { $0.routineId == routine.id }) else { return false }
            let allIds = Set(routine.items.map(\.id))
            guard !allIds.isEmpty else { return false }
            return allIds.isSubset(of: snap.completedItemIds)
        }.count
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
                    if lockSnapshot.isActivelyLocking || lockSnapshot.remainingItemCount > 0 {
                        Text(AppCopy.Today.lockHeroBadge)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.anchorAccent(scheme))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.anchorAccent(scheme).opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Text(AppCopy.Today.progressTitle(completed: completedRoutines, total: totalRoutines))
                        .font(AnchorTypography.cardTitle(scheme))
                        .foregroundStyle(Color.anchorText(scheme))

                    Text(AppCopy.Today.progressSubtitle(completed: completedRoutines, total: totalRoutines))
                        .font(.subheadline)
                        .foregroundStyle(Color.anchorSub(scheme))

                    if lockSnapshot.isActivelyLocking, blockSummary.hasAnyBlock {
                        HStack(alignment: .center, spacing: 8) {
                            Text(AppCopy.Today.lockingAppsLabel)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.anchorWarning(scheme))
                                .fixedSize(horizontal: true, vertical: false)
                            BlockedShieldDisplay(
                                summary: blockSummary,
                                maxApps: 5,
                                maxWebs: 3,
                                iconSize: 24
                            )
                        }
                    } else if completedRoutines < totalRoutines, lockSnapshot.remainingItemCount > 0 {
                        Text(AppCopy.Today.lockScheduled)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.anchorSub(scheme))
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(AnchorLayout.cardPadding)
        }
    }
}
