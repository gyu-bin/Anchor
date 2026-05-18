//
//  LockStatusWidget.swift
//  AnchorWidget
//

import SwiftUI
import WidgetKit

private enum LockWidgetKeys {
    static let appGroupID = "group.com.rbqls6651.anchor"
    static let lockActive = "widget.lockActive"
    static let lockRoutine = "widget.lockRoutineName"
}

struct LockStatusSnapshot {
    let isLockActive: Bool
    let routineName: String?

    static func load() -> LockStatusSnapshot {
        let suite = UserDefaults(suiteName: LockWidgetKeys.appGroupID)
        return LockStatusSnapshot(
            isLockActive: suite?.bool(forKey: LockWidgetKeys.lockActive) == true,
            routineName: suite?.string(forKey: LockWidgetKeys.lockRoutine)
        )
    }
}

struct LockStatusEntry: TimelineEntry {
    let date: Date
    let snapshot: LockStatusSnapshot
}

struct LockStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockStatusEntry {
        LockStatusEntry(date: Date(), snapshot: LockStatusSnapshot(isLockActive: true, routineName: "아침"))
    }

    func getSnapshot(in context: Context, completion: @escaping (LockStatusEntry) -> Void) {
        completion(LockStatusEntry(date: Date(), snapshot: .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockStatusEntry>) -> Void) {
        let entry = LockStatusEntry(date: Date(), snapshot: .load())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct LockStatusWidget: Widget {
    let kind = "LockStatus"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockStatusProvider()) { entry in
            LockStatusWidgetView(snapshot: entry.snapshot)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("잠금 상태")
        .description("루틴으로 앱이 잠겨 있을 때 잠금 화면에 표시해요.")
        .supportedFamilies([
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular,
        ])
    }
}

struct LockStatusWidgetView: View {
    @Environment(\.widgetFamily) private var widgetFamily

    let snapshot: LockStatusSnapshot

    var body: some View {
        switch widgetFamily {
        case .accessoryInline:
            inlineBody
        case .accessoryCircular:
            circularBody
        case .accessoryRectangular:
            rectangularBody
        default:
            inlineBody
        }
    }

    private var inlineBody: some View {
        if snapshot.isLockActive {
            Label("앱 잠금 중", systemImage: "lock.fill")
        } else {
            Label("잠금 없음", systemImage: "lock.open")
        }
    }

    private var circularBody: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: snapshot.isLockActive ? "lock.fill" : "lock.open")
                .font(.title2.weight(.semibold))
        }
    }

    private var rectangularBody: some View {
        HStack(spacing: 8) {
            Image(systemName: snapshot.isLockActive ? "lock.fill" : "lock.open")
                .font(.title3.weight(.semibold))
            VStack(alignment: .leading, spacing: 2) {
                if snapshot.isLockActive {
                    Text("앱 잠금 중")
                        .font(.headline)
                    if let name = snapshot.routineName {
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("루틴을 마치면 풀려요")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("잠금 없음")
                        .font(.headline)
                    Text("지금은 자유롭게 쓸 수 있어요")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview(as: .accessoryRectangular) {
    LockStatusWidget()
} timeline: {
    LockStatusEntry(date: Date(), snapshot: LockStatusSnapshot(isLockActive: true, routineName: "아침"))
    LockStatusEntry(date: Date(), snapshot: LockStatusSnapshot(isLockActive: false, routineName: nil))
}
