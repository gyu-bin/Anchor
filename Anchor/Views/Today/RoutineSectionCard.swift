//
//  RoutineSectionCard.swift
//  Anchor
//

import SwiftUI

struct RoutineSectionCard: View {
    @Environment(\.colorScheme) private var scheme

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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.name)
                        .font(.headline)
                        .foregroundStyle(Color.anchorText(scheme))
                    Text("\(completedCount)/\(totalCount) 완료")
                        .font(.caption)
                        .foregroundStyle(Color.anchorSub(scheme))
                }
                Spacer()
                if isFullyDone {
                    Label("완료", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            .padding(16)

            if !isFullyDone, blockSummary.hasAnyBlock {
                HStack(spacing: 4) {
                    Image(systemName: isActivelyLocking ? "lock.fill" : "lock")
                        .font(.caption2)
                    Text(isActivelyLocking ? "잠금 중" : "잠금 예정")
                        .font(.caption2)
                }
                .foregroundStyle(isActivelyLocking ? .orange : Color.anchorSub(scheme))
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

                BlockedShieldDisplay(summary: blockSummary, maxApps: 6, maxWebs: 6, iconSize: 26)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }

            Divider()
                .padding(.horizontal, 16)

            ForEach(sortedItems, id: \.id) { item in
                RoutineItemRow(
                    item: item,
                    isCompleted: log.completedItems.contains(item.id),
                    isCurrent: item.id == firstIncompleteId,
                    onTap: { onToggle(item) }
                )
                if item.id != sortedItems.last?.id {
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
        .background(Color("AnchorCard"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isFullyDone ? Color.green.opacity(0.3) : Color.clear,
                    lineWidth: 1.5
                )
        )
    }
}
