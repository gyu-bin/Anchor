//
//  HistoryView.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var tabRouter: TabRouter
    @EnvironmentObject private var premium: PremiumStore

    @Query(sort: [SortDescriptor(\DailyLog.date, order: .reverse)]) private var logs: [DailyLog]
    @Query(sort: [SortDescriptor(\Routine.order)]) private var routines: [Routine]

    @State private var paywallReason: PaywallReason?
    @State private var displayedMonth: Date = Date()

    private var routinesWithItems: [Routine] {
        routines.filter { !$0.items.isEmpty }
    }

    private var effectiveLogs: [DailyLog] {
        guard !premium.isPremium else { return logs }
        let cutoff = PremiumLimits.historyCutoffDate()
        return logs.filter { $0.date >= cutoff }
    }

    private var hasOlderHistory: Bool {
        guard !premium.isPremium else { return false }
        let cutoff = PremiumLimits.historyCutoffDate()
        return logs.contains { $0.date < cutoff }
    }

    var body: some View {
        NavigationStack {
            Group {
                if routinesWithItems.isEmpty {
                    emptyState
                } else {
                    historyContent
                }
            }
            .anchorScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { refreshWeeklyNotification() }
            .sheet(item: $paywallReason) { reason in
                PaywallSheet(reason: reason)
            }
        }
    }

    private var weeklySummaryBanner: some View {
        let fullDays = Self.weekFullDaysCount(
            logs: effectiveLogs,
            routines: routinesWithItems,
            now: Date(),
            cal: .current
        )
        return AnchorCard {
            Text(AppCopy.History.weeklySummary(fullDays: fullDays))
                .font(.subheadline)
                .foregroundStyle(Color.anchorText(scheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AnchorLayout.cardPadding)
        }
    }

    private func refreshWeeklyNotification() {
        let fullDays = Self.weekFullDaysCount(
            logs: effectiveLogs,
            routines: routinesWithItems,
            now: Date(),
            cal: .current
        )
        NotificationManager.updateWeeklySummaryContent(fullDays: fullDays)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(AppCopy.History.emptyTitle)
                    .font(.title3.bold())
                    .foregroundStyle(Color.anchorText(scheme))
                Text(AppCopy.History.emptyBody)
                    .font(.subheadline)
                    .foregroundStyle(Color.anchorSub(scheme))
                    .multilineTextAlignment(.center)
            }

            Button(AppCopy.History.emptyAction) {
                tabRouter.selectedTab = 1
            }
            .buttonStyle(AnchorButtonStyle())
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var historyContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AnchorLayout.sectionSpacing) {
                AnchorScreenHeader(title: AppCopy.History.title, subtitle: AppCopy.History.subtitle)

                weeklySummaryBanner

                if hasOlderHistory {
                    historyPremiumBanner
                }

                metricsGrid
                weeklyCard
                itemTotalsCard
                calendarCard
            }
            .padding(.horizontal, AnchorLayout.screenHorizontal)
            .padding(.bottom, 36)
        }
    }

    private var historyPremiumBanner: some View {
        Button {
            paywallReason = .history
        } label: {
            AnchorCard {
                HStack {
                    Text(AppCopy.Premium.historyBanner)
                        .font(.subheadline)
                        .foregroundStyle(Color.anchorText(scheme))
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.anchorSub(scheme))
                }
                .padding(AnchorLayout.cardPadding)
            }
        }
        .buttonStyle(.plain)
    }

    private var metricsGrid: some View {
        let cal = Calendar.current
        let streak = Self.streak(logs: effectiveLogs, routines: routinesWithItems, cal: cal)
        let best = Self.bestStreak(logs: effectiveLogs, routines: routinesWithItems, cal: cal)
        let rate = Self.monthCompletionRate(logs: effectiveLogs, routines: routinesWithItems, now: Date(), cal: cal)

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                metricTile(title: AppCopy.History.streak, value: "\(streak)", unit: "일", icon: "flame.fill")
                metricTile(title: AppCopy.History.bestStreak, value: "\(best)", unit: "일", icon: "trophy.fill")
            }
            metricTile(title: AppCopy.History.monthRate, value: "\(rate)", unit: "%", icon: "chart.pie.fill")
        }
    }

    /// `effectiveLogs` 기준 가장 오래된 달의 1일 (없으면 nil)
    private var earliestHistoryMonthStart: Date? {
        guard let oldest = effectiveLogs.map(\.date).min() else { return nil }
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: oldest)
        return cal.date(from: comps)
    }

    private func metricTile(title: String, value: String, unit: String, icon: String) -> some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.anchorAccent(scheme))
                    Spacer()
                }

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(AnchorTypography.metricValue(scheme))
                        .foregroundStyle(Color.anchorText(scheme))
                    Text(unit)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.anchorSub(scheme))
                }

                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.anchorSub(scheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AnchorLayout.cardPadding)
        }
    }

    private var weeklyCard: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 14) {
                AnchorSectionHeader(title: AppCopy.History.thisWeek)
                WeeklyBarChart(bars: Self.weekBars(logs: effectiveLogs, routines: routinesWithItems, now: Date(), cal: .current))
            }
            .padding(AnchorLayout.cardPadding)
        }
    }

    private var itemTotalsCard: some View {
        let totals = Self.itemCompletionCounts(logs: effectiveLogs, routines: routines)
        return AnchorCard {
            VStack(alignment: .leading, spacing: 14) {
                AnchorSectionHeader(title: AppCopy.History.byItem)

                if totals.isEmpty {
                    Text(AppCopy.History.noLogs)
                        .font(.subheadline)
                        .foregroundStyle(Color.anchorSub(scheme))
                } else {
                    VStack(spacing: 0) {
                        ForEach(totals, id: \.id) { row in
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.anchorHighlight(scheme))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: row.icon)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.anchorAccent(scheme))
                                }
                                Text(row.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color.anchorText(scheme))
                                Spacer()
                                Text(row.formatted)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.anchorSub(scheme))
                            }
                            .padding(.vertical, 11)

                            if row.id != totals.last?.id {
                                Divider()
                                    .padding(.leading, 48)
                            }
                        }
                    }
                }
            }
            .padding(AnchorLayout.cardPadding)
        }
    }

    private var calendarCard: some View {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: displayedMonth)
        let monthStart = cal.date(from: comps) ?? displayedMonth
        let range = cal.range(of: .day, in: .month, for: monthStart) ?? 1..<32
        let daysInMonth = range.count
        let firstWeekday = cal.component(.weekday, from: monthStart)
        let leading = (firstWeekday - 1) % 7

        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.setLocalizedDateFormatFromTemplate("yyyyMMMM")
        let title = df.string(from: monthStart)

        let nowComps = cal.dateComponents([.year, .month], from: Date())
        let canGoForward: Bool = {
            guard let y = comps.year, let m = comps.month,
                  let ny = nowComps.year, let nm = nowComps.month else { return false }
            return y < ny || (y == ny && m < nm)
        }()

        let canGoBackward: Bool = {
            guard let earliest = earliestHistoryMonthStart,
                  let prev = cal.date(byAdding: .month, value: -1, to: monthStart) else { return false }
            let prevComps = cal.dateComponents([.year, .month], from: prev)
            let earliestComps = cal.dateComponents([.year, .month], from: earliest)
            guard let py = prevComps.year, let pm = prevComps.month,
                  let ey = earliestComps.year, let em = earliestComps.month else { return false }
            return py > ey || (py == ey && pm >= em)
        }()

        var statuses: [Int: WeekdayCompletion] = [:]
        for day in 1...daysInMonth {
            guard let d = cal.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            statuses[day] = Self.dayStatus(logs: effectiveLogs, routines: routinesWithItems, day: d, cal: cal)
        }

        return AnchorCard {
            CalendarMonthView(
                monthTitle: title,
                referenceMonth: monthStart,
                daysInMonth: daysInMonth,
                firstWeekdayIndex: leading,
                dayStatuses: statuses,
                canGoBackward: canGoBackward,
                canGoForward: canGoForward,
                onPreviousMonth: {
                    guard canGoBackward,
                          let prev = cal.date(byAdding: .month, value: -1, to: monthStart) else { return }
                    displayedMonth = prev
                },
                onNextMonth: {
                    guard canGoForward,
                          let next = cal.date(byAdding: .month, value: 1, to: monthStart) else { return }
                    displayedMonth = next
                }
            )
            .padding(AnchorLayout.cardPadding)
        }
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
        let scheduled = RoutineSchedule.scheduledRoutines(routines, on: day, calendar: cal)
        guard !scheduled.isEmpty else { return .none }
        if RestDayStore.isRestDay(day, calendar: cal) { return .full }
        let start = day.startOfDay(in: cal)
        let dayLogs = logs.filter { cal.isDate($0.date, inSameDayAs: start) }
        let map = Dictionary(uniqueKeysWithValues: dayLogs.map { ($0.routineId, $0) })

        var anyProgress = false
        var allFull = true
        for r in scheduled {
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

    static func weekFullDaysCount(logs: [DailyLog], routines: [Routine], now: Date, cal: Calendar) -> Int {
        weekBars(logs: logs, routines: routines, now: now, cal: cal)
            .filter { $0.status == .full }
            .count
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

    static func bestStreak(logs: [DailyLog], routines: [Routine], cal: Calendar) -> Int {
        guard !routines.isEmpty else { return 0 }

        let today = cal.startOfDay(for: Date())
        var earliest = today
        for log in logs {
            let d = cal.startOfDay(for: log.date)
            if d < earliest { earliest = d }
        }

        var best = 0
        var current = 0
        var day = earliest
        while day <= today {
            let scheduled = RoutineSchedule.scheduledRoutines(routines, on: day, calendar: cal)
            let countsAsSuccess: Bool
            if scheduled.isEmpty {
                countsAsSuccess = true
            } else {
                countsAsSuccess = dayStatus(logs: logs, routines: routines, day: day, cal: cal) == .full
            }
            if countsAsSuccess {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return best
    }

    static func streak(logs: [DailyLog], routines: [Routine], cal: Calendar) -> Int {
        guard !routines.isEmpty else { return 0 }
        var count = 0
        var day = cal.startOfDay(for: Date())
        while true {
            let scheduled = RoutineSchedule.scheduledRoutines(routines, on: day, calendar: cal)
            let status: WeekdayCompletion
            if scheduled.isEmpty {
                status = .full
            } else {
                status = dayStatus(logs: logs, routines: routines, day: day, cal: cal)
            }
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
            let scheduled = RoutineSchedule.scheduledRoutines(routines, on: d, calendar: cal)
            denom += scheduled.count
            let start = d.startOfDay(in: cal)
            let dayLogs = logs.filter { cal.isDate($0.date, inSameDayAs: start) }
            let map = Dictionary(uniqueKeysWithValues: dayLogs.map { ($0.routineId, $0) })
            for r in scheduled {
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
        .environmentObject(TabRouter())
        .environmentObject(PremiumStore())
        .modelContainer(PreviewData.container)
}
