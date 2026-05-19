//
//  TodayProgressWidget.swift
//  AnchorWidget
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Keys
private enum WidgetKeys {
    static let appGroupID  = "group.com.rbqls6651.anchor"
    static let progress    = "widget.progressPercent"
    static let completed   = "widget.completedItemCount"
    static let total       = "widget.totalItemCount"
    static let lockActive  = "widget.lockActive"
}

// MARK: - Snapshot
struct WidgetSnapshot {
    let progress: Int
    let completedItems: Int
    let totalItems: Int
    let remainingItems: [WidgetPendingItem]
    let isLockActive: Bool

    var isDone: Bool {
        totalItems > 0 && remainingItems.isEmpty
    }

    var hasContent: Bool { totalItems > 0 }

    var progressSubtitle: String? {
        guard totalItems > 0 else { return nil }
        return "\(completedItems)/\(totalItems)"
    }

    static func load() -> WidgetSnapshot {
        let s = UserDefaults(suiteName: WidgetKeys.appGroupID)
        return WidgetSnapshot(
            progress: s?.integer(forKey: WidgetKeys.progress) ?? 0,
            completedItems: s?.integer(forKey: WidgetKeys.completed) ?? 0,
            totalItems: s?.integer(forKey: WidgetKeys.total) ?? 0,
            remainingItems: WidgetPendingItemCodec.decode(from: s),
            isLockActive: s?.bool(forKey: WidgetKeys.lockActive) ?? false
        )
    }
}

// MARK: - Entry & Provider
struct TodayProgressEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct TodayProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayProgressEntry {
        TodayProgressEntry(date: .now, snapshot: WidgetSnapshot(
            progress: 33,
            completedItems: 1,
            totalItems: 3,
            remainingItems: [
                WidgetPendingItem(itemName: "기도하기", routineName: "저녁의 시간", icon: "house"),
                WidgetPendingItem(itemName: "자기", routineName: "저녁의 시간", icon: "bed.double"),
            ],
            isLockActive: true
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayProgressEntry) -> Void) {
        let snap = context.isPreview ? placeholder(in: context).snapshot : WidgetSnapshot.load()
        completion(TodayProgressEntry(date: .now, snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayProgressEntry>) -> Void) {
        let entry = TodayProgressEntry(date: .now, snapshot: .load())
        let next = Calendar.current.date(byAdding: .minute, value: 5, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Widget
struct TodayProgressWidget: Widget {
    let kind = "TodayProgress"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProgressProvider()) { entry in
            TodayProgressWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("오늘 루틴")
        .description("남은 할 일 목록과 진행률을 확인하고 바로 체크해요.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Root View
struct TodayProgressWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme
    let snapshot: WidgetSnapshot

    private var tier: WidgetLayoutTier {
        family == .systemMedium ? .medium : .small
    }

    private var secondaryText: Color {
        scheme == .dark ? Color.white.opacity(0.55) : Color.black.opacity(0.45)
    }

    var body: some View {
        progressWidgetLayout(tier: tier)
            .widgetFullBleedChrome()
    }

    /// Small = Medium과 동일 구조(헤더 · 링+카드 목록 · 완료 체크), 크기만 축소
    private func progressWidgetLayout(tier: WidgetLayoutTier) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: tier.contentSpacing) {
                WidgetHeader(
                    isLockActive: snapshot.isLockActive,
                    compact: tier.headerCompact,
                    lockBadgeMini: tier.lockBadgeMini,
                    progressLabel: snapshot.progressSubtitle
                )

                if snapshot.isDone {
                    doneBody(tier: tier)
                } else if !snapshot.hasContent {
                    Text(tier == .small ? "오늘 루틴 없음" : "오늘 예정된 루틴이 없어요")
                        .font(.system(size: tier.emptyFontSize, weight: .medium))
                        .foregroundStyle(secondaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                } else {
                    remainingBody(tier: tier)
                }
            }
            .padding(.horizontal, tier.edgeInset)
            .padding(.top, tier.edgeInset)
            .padding(.bottom, snapshot.hasContent && !snapshot.isDone ? tier.bodyBottomPadding : tier.edgeInset)
            .frame(maxHeight: .infinity)

            if snapshot.hasContent && !snapshot.isDone {
                WidgetCompleteButton(compact: tier.completeButtonCompact)
            }
        }
    }

    private func remainingBody(tier: WidgetLayoutTier) -> some View {
        GeometryReader { geo in
            let visible = tier.visibleItemCount(
                availableHeight: geo.size.height,
                totalItems: snapshot.remainingItems.count
            )
            let dense = tier.useDenseRows(visibleCount: visible)
            let ringSide = tier.ringSize(forVisibleCount: visible)
            let listSpacing = tier.listRowSpacing(dense: dense)

            HStack(alignment: .top, spacing: tier.ringItemSpacing) {
                WidgetProgressRing(
                    progress: snapshot.progress,
                    lineWidth: tier.ringLineWidth,
                    fontSize: tier.ringFontSize
                )
                .frame(width: ringSide, height: ringSide)

                VStack(alignment: .leading, spacing: listSpacing) {
                    ForEach(snapshot.remainingItems.prefix(visible)) { item in
                        WidgetRemainingRow(
                            item: item,
                            compact: tier.rowCompact,
                            dense: dense && !tier.rowCompact
                        )
                    }
                    if snapshot.remainingItems.count > visible {
                        Text("+\(snapshot.remainingItems.count - visible)개 더")
                            .font(.system(size: tier.overflowFontSize, weight: .medium))
                            .foregroundStyle(secondaryText)
                            .padding(.leading, 2)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
    }

    private func doneBody(tier: WidgetLayoutTier) -> some View {
        HStack(spacing: tier == .small ? 8 : 12) {
            WidgetProgressRing(
                progress: 100,
                lineWidth: tier.ringLineWidth,
                fontSize: tier.ringFontSize
            )
            .frame(width: tier.ringSize, height: tier.ringSize)

            VStack(alignment: .leading, spacing: 3) {
                Text("오늘 루틴 완료!")
                    .font(.system(size: tier.doneTitleSize, weight: .bold))
                    .foregroundStyle(Color("AnchorAccent"))
                if tier == .medium {
                    Text("잘 하셨어요")
                        .font(.system(size: tier.doneSubtitleSize, weight: .medium))
                        .foregroundStyle(secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    TodayProgressWidget()
} timeline: {
    TodayProgressEntry(date: .now, snapshot: WidgetSnapshot(
        progress: 50,
        completedItems: 2,
        totalItems: 4,
        remainingItems: [
            WidgetPendingItem(itemName: "기도하기", routineName: "저녁의 시간", icon: "house"),
            WidgetPendingItem(itemName: "자기", routineName: "저녁의 시간", icon: "bed.double"),
        ],
        isLockActive: true
    ))
}

#Preview(as: .systemMedium) {
    TodayProgressWidget()
} timeline: {
    TodayProgressEntry(date: .now, snapshot: WidgetSnapshot(
        progress: 40,
        completedItems: 2,
        totalItems: 5,
        remainingItems: [
            WidgetPendingItem(itemName: "기도하기", routineName: "저녁의 시간", icon: "house"),
            WidgetPendingItem(itemName: "자기", routineName: "저녁의 시간", icon: "bed.double"),
            WidgetPendingItem(itemName: "독서하기", routineName: "저녁의 시간", icon: "book"),
            WidgetPendingItem(itemName: "정리하기", routineName: "아침", icon: "tray"),
        ],
        isLockActive: true
    ))
}
