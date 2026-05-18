//
//  HistoryView.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    @Query(sort: [SortDescriptor(\DailyLog.date, order: .reverse)]) private var logs: [DailyLog]
    @Query(sort: [SortDescriptor(\Routine.order)]) private var routines: [Routine]

    private var routinesWithItems: [Routine] {
        routines.filter { !$0.items.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    metricsGrid

                    weeklyCard

                    itemTotalsCard

                    calendarCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color.anchorBg(scheme).ignoresSafeArea())
            .navigationTitle("기록")
        }
    }

    private var metricsGrid: some View {
        let streak = Self.streak(logs: logs, routines: routinesWithItems, cal: .current)
        let rate = Self.monthCompletionRate(logs: logs, routines: routinesWithItems, now: Date(), cal: .current)

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricTile(title: "연속 완료", value: "\(streak)일")
            metricTile(title: "이번 달 완료율", value: "\(rate)%")
        }
    }

    private func metricTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.anchorSub(scheme))
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Color.anchorText(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.anchorCard(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var weeklyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("이번 주")
                .font(.headline)
                .foregroundStyle(Color.anchorText(scheme))

            WeeklyBarChart(bars: Self.weekBars(logs: logs, routines: routinesWithItems, now: Date(), cal: .current))
        }
        .padding(14)
        .background(Color.anchorCard(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var itemTotalsCard: some View {
        let totals = Self.itemCompletionCounts(logs: logs, routines: routines)
        return VStack(alignment: .leading, spacing: 12) {
            Text("항목별 완료 횟수")
                .font(.headline)
                .foregroundStyle(Color.anchorText(scheme))

            if totals.isEmpty {
                Text("아직 기록이 없습니다")
                    .font(.subheadline)
                    .foregroundStyle(Color.anchorSub(scheme))
            } else {
                ForEach(totals, id: \.id) { row in
                    HStack {
                        Image(systemName: row.icon)
                            .foregroundStyle(Color.anchorAccent(scheme))
                            .frame(width: 28)
                        Text(row.name)
                            .foregroundStyle(Color.anchorText(scheme))
                        Spacer()
                        Text(row.formatted)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.anchorSub(scheme))
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(14)
        .background(Color.anchorCard(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var calendarCard: some View {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        let monthStart = cal.date(from: comps) ?? now
        let range = cal.range(of: .day, in: .month, for: monthStart) ?? 1..<32
        let daysInMonth = range.count

        let firstWeekday = cal.component(.weekday, from: monthStart) // 1 Sun
        let leading = (firstWeekday - 1) % 7

        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.setLocalizedDateFormatFromTemplate("yyyyMMMM")
        let title = df.string(from: monthStart)

        var statuses: [Int: WeekdayCompletion] = [:]
        for day in 1...daysInMonth {
            guard let d = cal.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            statuses[day] = Self.dayStatus(logs: logs, routines: routinesWithItems, day: d, cal: cal)
        }

        return CalendarMonthView(
            monthTitle: title,
            daysInMonth: daysInMonth,
            firstWeekdayIndex: leading,
            dayStatuses: statuses
        )
    }
}

struct ItemTotalRow: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let count: Int

    var formatted: String {
        "\(count)회"
    }
}

extension HistoryView {
    static func dayStatus(logs: [DailyLog], routines: [Routine], day: Date, cal: Calendar) -> WeekdayCompletion {
        guard !routines.isEmpty else { return .none }
        let start = day.startOfDay(in: cal)
        let dayLogs = logs.filter { cal.isDate($0.date, inSameDayAs: start) }
        let map = Dictionary(uniqueKeysWithValues: dayLogs.map { ($0.routineId, $0) })

        var anyProgress = false
        var allFull = true
        for r in routines {
            guard let log = map[r.id] else {
                allFull = false
                continue
            }
            if !log.completedItems.isEmpty { anyProgress = true }
            if !log.isFullyCompleted { allFull = false }
        }

        if allFull { return .full }
        if anyProgress { return .partial }
        return .none
    }

    static func weekBars(logs: [DailyLog], routines: [Routine], now: Date, cal: Calendar) -> [WeekdayBar] {
        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = TimeZone.current
        let weekStart = iso.date(from: iso.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now

        let labels = ["월", "화", "수", "목", "금", "토", "일"]
        return (0..<7).map { idx in
            let day = iso.date(byAdding: .day, value: idx, to: weekStart) ?? now
            let status = dayStatus(logs: logs, routines: routines, day: day, cal: iso)
            let value: Double
            switch status {
            case .full:
                value = 3
            case .partial:
                value = 2
            case .none:
                value = 0.6
            }
            return WeekdayBar(label: labels[idx], value: value, status: status)
        }
    }

    static func streak(logs: [DailyLog], routines: [Routine], cal: Calendar) -> Int {
        guard !routines.isEmpty else { return 0 }
        var count = 0
        var day = cal.startOfDay(for: Date())
        while true {
            let status = dayStatus(logs: logs, routines: routines, day: day, cal: cal)
            if status == .full {
                count += 1
            } else {
                break
            }
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    static func monthCompletionRate(logs: [DailyLog], routines: [Routine], now: Date, cal: Calendar) -> Int {
        guard !routines.isEmpty else { return 0 }
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let monthStart = cal.date(from: comps) else { return 0 }
        guard let monthRange = cal.range(of: .day, in: .month, for: monthStart) else { return 0 }

        let todayStart = cal.startOfDay(for: now)
        let todayDay = cal.component(.day, from: now)

        var numer = 0
        var denom = 0
        for day in monthRange where day <= todayDay {
            guard let d = cal.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            if d > todayStart { break }
            denom += routines.count
            let start = d.startOfDay(in: cal)
            let dayLogs = logs.filter { cal.isDate($0.date, inSameDayAs: start) }
            let map = Dictionary(uniqueKeysWithValues: dayLogs.map { ($0.routineId, $0) })
            for r in routines {
                if let log = map[r.id], log.isFullyCompleted {
                    numer += 1
                }
            }
        }
        guard denom > 0 else { return 0 }
        return Int((Double(numer) / Double(denom) * 100.0).rounded())
    }

    static func itemCompletionCounts(logs: [DailyLog], routines: [Routine]) -> [ItemTotalRow] {
        var totals: [UUID: (name: String, icon: String, count: Int)] = [:]

        let itemById: [UUID: RoutineItem] = routines
            .flatMap(\.items)
            .reduce(into: [:]) { $0[$1.id] = $1 }

        for log in logs {
            for itemId in log.completedItems {
                guard let item = itemById[itemId] else { continue }
                let prev = totals[itemId]?.count ?? 0
                totals[itemId] = (item.name, item.icon, prev + 1)
            }
        }

        return totals
            .map { id, v in ItemTotalRow(id: id, name: v.name, icon: v.icon, count: v.count) }
            .sorted { $0.count > $1.count }
    }
}

#Preview {
    HistoryView()
        .modelContainer(PreviewData.container)
}
