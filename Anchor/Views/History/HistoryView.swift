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
    @State private var selectedDay: HistoryDaySelection?

    private var routinesWithItems: [Routine] {
        routines.filter { !$0.items.isEmpty }
    }

    private var effectiveLogs: [DailyLog] {
        let liveIds = Set(routines.map(\.id))
        let minimum = premium.isPremium ? nil : PremiumLimits.historyCutoffDate()
        return DailyLogFetcher.fetchedLogs(
            liveRoutineIds: liveIds,
            context: modelContext,
            minimumDate: minimum
        )
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
                    ScrollView {
                        VStack(alignment: .leading, spacing: AnchorLayout.sectionSpacing) {
                            AnchorScreenHeader(
                                title: AppCopy.History.title,
                                subtitle: AppCopy.History.subtitle
                            )
                            emptyState
                        }
                        .padding(.horizontal, AnchorLayout.screenHorizontal)
                        .padding(.bottom, 36)
                    }
                } else {
                    historyContent
                }
            }
            .anchorScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                refreshWeeklyNotification()
            }
            .sheet(item: $paywallReason) { reason in
                PaywallSheet(reason: reason)
            }
            .sheet(item: $selectedDay) { selection in
                HistoryDayDetailSheet(
                    snapshot: HistoryDaySnapshot.build(
                        date: selection.date,
                        logs: effectiveLogs,
                        routines: routinesWithItems
                    )
                )
            }
        }
    }

    private var weeklySummaryBanner: some View {
        let fullDays = HistoryAnalytics.weekFullDaysCount(
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
        let fullDays = HistoryAnalytics.weekFullDaysCount(
            logs: effectiveLogs,
            routines: routinesWithItems,
            now: Date(),
            cal: .current
        )
        NotificationManager.updateWeeklySummaryContent(fullDays: fullDays)
    }

    private var emptyState: some View {
        AnchorEmptyState(
            icon: "chart.bar",
            title: AppCopy.History.emptyTitle,
            message: AppCopy.History.emptyBody,
            actionTitle: AppCopy.History.emptyAction
        ) {
            tabRouter.openRoutines(andCreateNew: true)
        }
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
                historyStatusCard
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
        .accessibilityLabel(AppCopy.Premium.historyBanner)
        .accessibilityHint("탭하여 프리미엄 안내 보기")
    }

    private var metricsGrid: some View {
        let cal = Calendar.current
        let streak = HistoryAnalytics.streak(logs: effectiveLogs, routines: routinesWithItems, cal: cal)
        let best = HistoryAnalytics.bestStreak(logs: effectiveLogs, routines: routinesWithItems, cal: cal)
        let month = HistoryAnalytics.monthCompletionSummary(
            logs: effectiveLogs,
            routines: routinesWithItems,
            now: Date(),
            cal: cal
        )

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                metricTile(title: AppCopy.History.streak, value: "\(streak)", unit: "일", icon: "flame.fill")
                metricTile(title: AppCopy.History.bestStreak, value: "\(best)", unit: "일", icon: "trophy.fill")
            }
            monthRateMetricTile(month: month)
        }
    }

    private func monthRateMetricTile(month: MonthCompletionSummary) -> some View {
        let progress: Double = month.scheduledSlots > 0
            ? Double(month.completedSlots) / Double(month.scheduledSlots)
            : 0

        return AnchorCard {
            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    ProgressRingView(progress: progress, lineWidth: 7)
                    VStack(spacing: 0) {
                        Text("\(month.percent)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.anchorText(scheme))
                        Text("%")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.anchorSub(scheme))
                    }
                }
                .frame(width: 76, height: 76)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(AppCopy.History.monthRate) \(month.percent)%")

                VStack(alignment: .leading, spacing: 8) {
                    Text(AppCopy.History.monthRate)
                        .font(AnchorTypography.cardTitle(scheme))
                        .foregroundStyle(Color.anchorText(scheme))

                    Text(AppCopy.History.monthRateHint)
                        .font(.subheadline)
                        .foregroundStyle(Color.anchorSub(scheme))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    if month.scheduledSlots > 0 {
                        Text(
                            AppCopy.History.monthRateDetail(
                                completed: month.completedSlots,
                                scheduled: month.scheduledSlots
                            )
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.anchorAccent(scheme))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.anchorAccent(scheme).opacity(0.12))
                        .clipShape(Capsule())
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(AnchorLayout.cardPadding)
        }
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
                WeeklyBarChart(bars: HistoryAnalytics.weekBars(logs: effectiveLogs, routines: routinesWithItems, now: Date(), cal: .current))
            }
            .padding(AnchorLayout.cardPadding)
        }
    }

    private var itemTotalsCard: some View {
        let totals = HistoryAnalytics.itemCompletionCounts(logs: effectiveLogs, routines: routines)
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

    private var historyStatusCard: some View {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: displayedMonth)
        let monthStart = cal.date(from: comps) ?? displayedMonth
        let missedCount = HistoryAnalytics.missedDeadlineDaysInMonth(
            logs: effectiveLogs,
            routines: routinesWithItems,
            monthStart: monthStart,
            cal: cal
        )

        return AnchorCard {
            VStack(alignment: .leading, spacing: 14) {
                AnchorSectionHeader(title: AppCopy.History.statusTitle)

                HStack(spacing: 16) {
                    HistoryStatusLegendItem(color: Color.anchorSuccess(scheme).opacity(0.35), label: AppCopy.History.legendFull)
                    HistoryStatusLegendItem(color: Color.anchorWarning(scheme).opacity(0.35), label: AppCopy.History.legendMissed)
                    HistoryStatusLegendItem(color: Color.anchorSubBg(scheme), label: AppCopy.History.legendNone)
                }

                Text(missedCount > 0 ? AppCopy.History.monthMissedDays(missedCount) : AppCopy.History.monthMissedNone)
                    .font(.subheadline)
                    .foregroundStyle(missedCount > 0 ? Color.anchorWarning(scheme) : Color.anchorSub(scheme))
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
            guard let prev = cal.date(byAdding: .month, value: -1, to: monthStart) else { return false }
            let prevComps = cal.dateComponents([.year, .month], from: prev)
            guard let py = prevComps.year, let pm = prevComps.month,
                  let ny = nowComps.year, let nm = nowComps.month else { return false }
            return py < ny || (py == ny && pm <= nm)
        }()

        var statuses: [Int: WeekdayCompletion] = [:]
        for day in 1...daysInMonth {
            guard let d = cal.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            statuses[day] = HistoryAnalytics.dayStatus(logs: effectiveLogs, routines: routinesWithItems, day: d, cal: cal)
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
                },
                onSelectDay: { day in
                    guard let date = cal.date(byAdding: .day, value: day - 1, to: monthStart) else { return }
                    if !PremiumLimits.includesHistoryDate(date, isPremium: premium.isPremium, calendar: cal) {
                        paywallReason = .history
                        return
                    }
                    selectedDay = HistoryDaySelection(date: date, calendar: cal)
                }
            )
            .padding(AnchorLayout.cardPadding)
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(TabRouter())
        .environmentObject(PremiumStore())
        .modelContainer(PreviewData.container)
}
