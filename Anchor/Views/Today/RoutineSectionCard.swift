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
    var unlockSecondsLeft: Int = 0
    var onUnlock: (() -> Void)? = nil
    var onRelockNow: (() -> Void)? = nil
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

    private func formatCountdown(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return m > 0 ? "\(m)분 \(s)초" : "\(s)초"
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
                    if unlockSecondsLeft > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.open")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.anchorAccent(scheme))
                            Text("\(formatCountdown(unlockSecondsLeft)) 후 잠금")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.anchorSub(scheme))
                            Spacer()
                            Button("지금 잠금") { onRelockNow?() }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.anchorAccent(scheme))
                        }
                        .padding(.horizontal, AnchorLayout.cardPadding)
                        .padding(.bottom, blockSummary.hasAnyBlock ? 4 : 10)

                        if blockSummary.hasAnyBlock {
                            BlockedShieldDisplay(summary: blockSummary, maxApps: 6, maxWebs: 6, iconSize: 26)
                                .padding(.horizontal, AnchorLayout.cardPadding)
                                .padding(.bottom, 10)
                                .opacity(0.4)
                        }
                    } else {
                        let lockMessage = ShieldManager.routineLockMessage(routine: routine, modelContext: modelContext)
                        if blockSummary.hasAnyBlock || lockMessage != AppCopy.Routine.lockScheduled {
                            if blockSummary.hasAnyBlock && isActivelyLocking {
                                HStack(spacing: 8) {
                                    Text(lockMessage)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(Color.anchorWarning(scheme))
                                    Spacer()
                                    Button("10분 해제") { onUnlock?() }
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.anchorAccent(scheme))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.anchorAccent(scheme).opacity(0.1))
                                        .clipShape(Capsule())
                                }
                                .padding(.horizontal, AnchorLayout.cardPadding)
                                .padding(.bottom, 4)
                            } else {
                                Text(lockMessage)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(isActivelyLocking ? Color.anchorWarning(scheme) : Color.anchorSub(scheme))
                                    .padding(.horizontal, AnchorLayout.cardPadding)
                                    .padding(.bottom, blockSummary.hasAnyBlock ? 4 : 10)
                            }

                            if blockSummary.hasAnyBlock {
                                BlockedShieldDisplay(summary: blockSummary, maxApps: 6, maxWebs: 6, iconSize: 26)
                                    .padding(.horizontal, AnchorLayout.cardPadding)
                                    .padding(.bottom, 10)
                            }
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
