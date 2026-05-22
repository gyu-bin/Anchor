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
    let logSnapshot: TodayLogSnapshot
    let blockSummary: BlockedShieldSummary
    let isActivelyLocking: Bool
    var unlockSecondsLeft: Int = 0
    var tempUnlockUsedToday: Bool = false
    var canExtendDeadline: Bool = false
    var onUnlock: (() -> Void)? = nil
    var onRelockNow: (() -> Void)? = nil
    var onExtendDeadline: (() -> Void)? = nil
    let onToggle: (RoutineItem) -> Void

    private var sortedItems: [RoutineItem] {
        routine.items.sorted { $0.order < $1.order }
    }

    private var completedCount: Int {
        logSnapshot.completedItemIds.filter { id in routine.items.contains(where: { $0.id == id }) }.count
    }

    private var totalCount: Int {
        routine.items.count
    }

    private var isFullyDone: Bool {
        logSnapshot.isFullyCompleted
    }

    private func formatCountdown(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return m > 0 ? "\(m)분 \(s)초" : "\(s)초"
    }

    private var firstIncompleteId: UUID? {
        sortedItems.first { !logSnapshot.completedItemIds.contains($0.id) }?.id
    }

    private var hasRoutineStartedToday: Bool {
        ShieldManager.hasRoutineStartedToday(routine)
    }

    private var progressSubtitle: String {
        var text = AppCopy.Routine.sectionProgress(done: completedCount, total: totalCount)
        if let duration = RoutineDuration.formattedTotal(items: routine.items) {
            text += " · \(duration)"
        }
        return text
    }

    @ViewBuilder
    private var headerSubtitle: some View {
        if isFullyDone {
            Text(progressSubtitle)
                .font(.subheadline)
                .foregroundStyle(Color.anchorSub(scheme))
        } else if !hasRoutineStartedToday {
            Text(AppCopy.Routine.startsAt(startTimeText))
                .font(.subheadline)
                .foregroundStyle(Color.anchorSub(scheme))
        } else {
            Text(progressSubtitle)
                .font(.subheadline)
                .foregroundStyle(Color.anchorSub(scheme))
        }
    }

    private var startTimeText: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "a h:mm"
        return df.string(from: routine.startTime)
    }

    private func canUncheckItem(_ item: RoutineItem) -> Bool {
        guard logSnapshot.completedItemIds.contains(item.id) else { return true }
        return !RoutineDeadline.isTodayDeadlinePassed(for: routine)
    }

    private func lockCapsuleButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.anchorAccent(scheme))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.anchorAccent(scheme).opacity(0.1))
            .clipShape(Capsule())
    }

    var body: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.name)
                            .font(AnchorTypography.cardTitle(scheme))
                            .foregroundStyle(Color.anchorText(scheme))
                        headerSubtitle
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
                                HStack(spacing: 6) {
                                    Text(lockMessage)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(Color.anchorWarning(scheme))
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.85)
                                    Spacer(minLength: 4)
                                    if canExtendDeadline {
                                        lockCapsuleButton(AppCopy.Routine.extendDeadline) {
                                            onExtendDeadline?()
                                        }
                                    } else if !tempUnlockUsedToday {
                                        lockCapsuleButton(AppCopy.Routine.tempUnlockTenMin) {
                                            onUnlock?()
                                        }
                                    }
                                }
                                .padding(.horizontal, AnchorLayout.cardPadding)
                                .padding(.bottom, 4)
                            } else if canExtendDeadline, lockMessage != AppCopy.Routine.lockScheduled {
                                HStack(spacing: 8) {
                                    Text(lockMessage)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(Color.anchorSub(scheme))
                                        .lineLimit(2)
                                    Spacer(minLength: 4)
                                    lockCapsuleButton(AppCopy.Routine.extendDeadline) {
                                        onExtendDeadline?()
                                    }
                                }
                                .padding(.horizontal, AnchorLayout.cardPadding)
                                .padding(.bottom, blockSummary.hasAnyBlock ? 4 : 10)
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
                    let deadlinePassed = RoutineDeadline.isTodayDeadlinePassed(for: routine)
                    ForEach(sortedItems, id: \.id) { item in
                        RoutineItemRow(
                            item: item,
                            isCompleted: logSnapshot.completedItemIds.contains(item.id),
                            isCurrent: item.id == firstIncompleteId,
                            allowsUncheck: canUncheckItem(item),
                            isDeadlineLocked: deadlinePassed,
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
