//
//  LockStatusWidget.swift
//  AnchorWidget
//

import SwiftUI
import WidgetKit

private enum LockWidgetKeys {
    static let appGroupID  = "group.com.rbqls6651.anchor"
    static let progress    = "widget.progressPercent"
    static let nextItem    = "widget.nextItemName"
    static let nextRoutine = "widget.nextRoutineName"
    static let lockActive  = "widget.lockActive"
    static let lockRoutine = "widget.lockRoutineName"
}

// MARK: - Snapshot
struct LockStatusSnapshot {
    let isLockActive: Bool
    let routineName: String?
    let progress: Int
    let nextItem: String?

    var isDone: Bool { progress >= 100 && nextItem == nil }
    var hasContent: Bool { nextItem != nil || nextRoutine != nil || progress > 0 }
    var nextRoutine: String? { routineName }

    static func load() -> LockStatusSnapshot {
        let s = UserDefaults(suiteName: LockWidgetKeys.appGroupID)
        return LockStatusSnapshot(
            isLockActive: s?.bool(forKey: LockWidgetKeys.lockActive) == true,
            routineName:  s?.string(forKey: LockWidgetKeys.lockRoutine)
                       ?? s?.string(forKey: LockWidgetKeys.nextRoutine),
            progress:    s?.integer(forKey: LockWidgetKeys.progress) ?? 0,
            nextItem:    s?.string(forKey: LockWidgetKeys.nextItem)
        )
    }
}

struct LockStatusEntry: TimelineEntry {
    let date: Date
    let snapshot: LockStatusSnapshot
}

struct LockStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockStatusEntry {
        LockStatusEntry(date: .now, snapshot: LockStatusSnapshot(
            isLockActive: true, routineName: "미라클 모닝", progress: 60, nextItem: "독서하기"
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (LockStatusEntry) -> Void) {
        let snap = context.isPreview ? placeholder(in: context).snapshot : LockStatusSnapshot.load()
        completion(LockStatusEntry(date: .now, snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockStatusEntry>) -> Void) {
        let entry = LockStatusEntry(date: .now, snapshot: .load())
        let next  = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Widget
struct LockStatusWidget: Widget {
    let kind = "LockStatus"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockStatusProvider()) { entry in
            LockStatusWidgetView(snapshot: entry.snapshot)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("잠금 상태")
        .description("루틴 진행 중 잠금화면에서 진행률과 잠금 상태를 확인해요.")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - View
struct LockStatusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: LockStatusSnapshot

    var body: some View {
        switch family {
        case .accessoryInline:     inlineBody
        case .accessoryCircular:   circularBody
        case .accessoryRectangular: rectangularBody
        default:                   inlineBody
        }
    }

    // 한 줄: 다음 항목 or 잠금 상태
    private var inlineBody: some View {
        Group {
            if snapshot.isDone {
                Label("루틴 완료", systemImage: "checkmark.seal.fill")
            } else if let item = snapshot.nextItem {
                Label(item, systemImage: snapshot.isLockActive ? "lock.fill" : "circle")
            } else {
                Label(snapshot.isLockActive ? "앱 잠금 중" : "잠금 없음",
                      systemImage: snapshot.isLockActive ? "lock.fill" : "lock.open")
            }
        }
    }

    // 원형: 진행률 게이지
    private var circularBody: some View {
        Gauge(value: Double(snapshot.progress), in: 0...100) {
            Image(systemName: snapshot.isDone
                  ? "checkmark.circle.fill"
                  : (snapshot.isLockActive ? "lock.fill" : "checkmark.circle"))
        } currentValueLabel: {
            Text("\(snapshot.progress)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
    }

    // 직사각형: 루틴 이름 + 진행률 + 다음 항목
    private var rectangularBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            if snapshot.isDone {
                Label("오늘 루틴 완료!", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 13, weight: .semibold))
            } else {
                HStack(spacing: 4) {
                    Image(systemName: snapshot.isLockActive ? "lock.fill" : "checkmark.circle")
                        .font(.system(size: 11))
                    if let name = snapshot.routineName {
                        Text(name)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                    } else {
                        Text(snapshot.isLockActive ? "앱 잠금 중" : "루틴 진행 중")
                            .font(.system(size: 13, weight: .semibold))
                    }
                }
                if let item = snapshot.nextItem {
                    Text("다음: \(item) · \(snapshot.progress)% 완료")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("\(snapshot.progress)% 완료")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview
#Preview(as: .accessoryRectangular) {
    LockStatusWidget()
} timeline: {
    LockStatusEntry(date: .now, snapshot: LockStatusSnapshot(
        isLockActive: true, routineName: "미라클 모닝", progress: 60, nextItem: "독서하기"
    ))
    LockStatusEntry(date: .now, snapshot: LockStatusSnapshot(
        isLockActive: false, routineName: nil, progress: 100, nextItem: nil
    ))
}
