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

    private var headerText: String {
        if completedRoutines == totalRoutines && totalRoutines > 0 {
            return "오늘 모두 완료했어요 🎉"
        }
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 12 ? "좋은 아침이에요" : "수고했어요"
    }

    var body: some View {
        AnchorCard {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.anchorSubBg(scheme), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color("AnchorAccent"),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6), value: progress)
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.anchorText(scheme))
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 6) {
                    Text(headerText)
                        .font(.headline)
                        .foregroundStyle(Color.anchorText(scheme))
                    Text("\(completedRoutines)/\(totalRoutines) 루틴 완료")
                        .font(.caption)
                        .foregroundStyle(Color.anchorSub(scheme))

                    if completedRoutines < totalRoutines, blockSummary.hasAnyBlock {
                        Label(
                            isActivelyLocking ? "잠금 중" : "잠금 예정",
                            systemImage: isActivelyLocking ? "lock.fill" : "lock"
                        )
                        .font(.caption2)
                        .foregroundStyle(isActivelyLocking ? .orange : Color.anchorSub(scheme))

                        BlockedShieldDisplay(summary: blockSummary, maxApps: 8, maxWebs: 8)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }
}
