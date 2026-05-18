//
//  TodayProgressWidget.swift
//  AnchorWidget
//

import SwiftUI
import WidgetKit

private enum WidgetKeys {
    static let appGroupID = "group.com.rbqls6651.anchor"
    static let progress = "widget.progressPercent"
    static let nextItem = "widget.nextItemName"
    static let nextRoutine = "widget.nextRoutineName"
    static let premiumUnlocked = "premium.isUnlocked"
}

struct WidgetSnapshot {
    let progress: Int
    let nextItem: String?
    let nextRoutine: String?
    let isPremium: Bool

    static func load() -> WidgetSnapshot {
        let suite = UserDefaults(suiteName: WidgetKeys.appGroupID)
        return WidgetSnapshot(
            progress: suite?.integer(forKey: WidgetKeys.progress) ?? 0,
            nextItem: suite?.string(forKey: WidgetKeys.nextItem),
            nextRoutine: suite?.string(forKey: WidgetKeys.nextRoutine),
            isPremium: suite?.bool(forKey: WidgetKeys.premiumUnlocked) == true
        )
    }
}

struct TodayProgressEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct TodayProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayProgressEntry {
        TodayProgressEntry(date: Date(), snapshot: WidgetSnapshot(progress: 42, nextItem: "독서", nextRoutine: "아침", isPremium: true))
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayProgressEntry) -> Void) {
        completion(TodayProgressEntry(date: Date(), snapshot: .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayProgressEntry>) -> Void) {
        let entry = TodayProgressEntry(date: Date(), snapshot: .load())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct TodayProgressWidget: Widget {
    let kind = "TodayProgress"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProgressProvider()) { entry in
            TodayProgressWidgetView(snapshot: entry.snapshot)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("오늘 루틴")
        .description("진행률과 다음 할 일을 보여줘요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TodayProgressWidgetView: View {
    @Environment(\.widgetFamily) private var widgetFamily

    let snapshot: WidgetSnapshot

    var body: some View {
        if widgetFamily == .systemMedium, snapshot.isPremium {
            mediumBody
        } else {
            smallBody
        }
    }

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("오늘")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(snapshot.progress)%")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mediumBody: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("오늘")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(snapshot.progress)%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
            }
            Spacer(minLength: 0)
            if let item = snapshot.nextItem {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("다음")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(item)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.trailing)
                    if let routine = snapshot.nextRoutine {
                        Text(routine)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview(as: .systemSmall) {
    TodayProgressWidget()
} timeline: {
    TodayProgressEntry(date: Date(), snapshot: WidgetSnapshot(progress: 60, nextItem: nil, nextRoutine: nil, isPremium: false))
}
