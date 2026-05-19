//
//  RoutineSectionCard.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct RoutineSectionCard: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext

    let routine: Routine
    let log: DailyLog
    let blockSummary: BlockedShieldSummary
    let isActivelyLocking: Bool
    let onToggle: (RoutineItem) -> Void

    private var sortedItems: [RoutineItem] {
        routine.items.sorted { $0.order < $1.order }
    }

    private var completedCount: Int {
        log.completedItems.filter { id in routine.items.contains(where: { $0.id == id }) }.count
    }

    private var totalCount: Int {
        routine.items.count
    }

    private var isFullyDone: Bool {
        log.isFullyCompleted
    }

    private var firstIncompleteId: UUID? {
        sortedItems.first { !log.completedItems.contains($0.id) }?.id
    }

    private var progressSubtitle: String {
        var text = AppCopy.Routine.sectionProgress(done: completedCount, total: totalCount)
        if let duration = RoutineDuration.formattedTotal(items: routine.items) {
            text += " · \(duration)"
        }
        return text
    }

    private var startTimeText: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "a h:mm"
        return df.string(from: routine.startTime)
    }

    private var isBeforeStartTime: Bool {
        let cal = Calendar.current
        let now = Date.now
        let comps = cal.dateComponents([.hour, .minute], from: routine.startTime)
        guard let todayStart = cal.date(
            bySettingHour: comps.hour ?? 0,
            minute: comps.minute ?? 0,
            second: 0,
            of: now
        ) else { return false }
        return now < todayStart
    }

    var body: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.name)
                            .font(AnchorTypography.cardTitle(scheme))
                            .foregroundStyle(Color.anchorText(scheme))
                        Text(progressSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.anchorSub(scheme))
                        if !isFullyDone && isBeforeStartTime {
                            Text("\(startTimeText)에 시작해요")
                                .font(.caption)
                                .foregroundStyle(Color.anchorSub(scheme).opacity(0.8))
                        }
                    }
                    Spacer()
                    if isFullyDone {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title3)
                            .foregroundStyle(Color.anchorSuccess(scheme))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .padding(AnchorLayout.cardPadding)

                if !isFullyDone {
                    let lockMessage = ShieldManager.routineLockMessage(routine: routine, modelContext: modelContext)
                    if blockSummary.hasAnyBlock || lockMessage != AppCopy.Routine.lockScheduled {
                        Text(lockMessage)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(isActivelyLocking ? Color.anchorWarning(scheme) : Color.anchorSub(scheme))
                            .padding(.horizontal, AnchorLayout.cardPadding)
                            .padding(.bottom, blockSummary.hasAnyBlock ? 4 : 10)

                        if blockSummary.hasAnyBlock {
                            BlockedShieldDisplay(summary: blockSummary, maxApps: 6, maxWebs: 6, iconSize: 26)
                                .padding(.horizontal, AnchorLayout.cardPadding)
                                .padding(.bottom, 10)
                        }
                    }
                }

                VStack(spacing: 4) {
                    ForEach(sortedItems, id: \.id) { item in
                        RoutineItemRow(
                            item: item,
                            isCompleted: log.completedItems.contains(item.id),
                            isCurrent: item.id == firstIncompleteId,
                            onTap: { onToggle(item) }
                        )
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AnchorLayout.cardRadius, style: .continuous)
                .stroke(
                    isFullyDone ? Color.anchorSuccess(scheme).opacity(0.4) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .opacity(isFullyDone ? 0.72 : 1)
    }
}
