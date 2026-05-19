//
//  HistoryDayDetailSheet.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct HistoryDaySelection: Identifiable {
    let date: Date

    var id: TimeInterval { date.timeIntervalSince1970 }

    init(date: Date, calendar: Calendar = .current) {
        self.date = calendar.startOfDay(for: date)
    }
}

enum HistoryDayRoutineStatus {
    case completed
    case partial
    case missed
    case waiting
    case upcoming
}

struct HistoryDayRoutineRow: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let subtitle: String
    let completedCount: Int
    let totalCount: Int
    let status: HistoryDayRoutineStatus
}

struct HistoryDaySnapshot {
    let date: Date
    let title: String
    let overallStatus: WeekdayCompletion
    let isRestDay: Bool
    let isFuture: Bool
    let routines: [HistoryDayRoutineRow]

    static func build(
        date: Date,
        logs: [DailyLog],
        routines: [Routine],
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> HistoryDaySnapshot {
        let day = calendar.startOfDay(for: date)
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.setLocalizedDateFormatFromTemplate("yyyyMMMMdEEE")
        let title = df.string(from: day)

        let isFuture = RoutineDeadline.isFutureDay(day, calendar: calendar, now: now)
        let isRest = RestDayStore.isRestDay(day, calendar: calendar)
        let overall = HistoryAnalytics.dayStatus(logs: logs, routines: routines, day: day, cal: calendar)

        if isRest {
            return HistoryDaySnapshot(
                date: day,
                title: title,
                overallStatus: overall,
                isRestDay: true,
                isFuture: isFuture,
                routines: []
            )
        }

        let scheduled = RoutineSchedule.scheduledRoutinesExisting(
            routines,
            logs: logs,
            on: day,
            calendar: calendar
        )

        let rows = scheduled.map { routine in
            routineRow(
                routine,
                day: day,
                logs: logs,
                calendar: calendar,
                now: now,
                isFutureDay: isFuture
            )
        }

        return HistoryDaySnapshot(
            date: day,
            title: title,
            overallStatus: overall,
            isRestDay: false,
            isFuture: isFuture,
            routines: rows
        )
    }

    private static func routineRow(
        _ routine: Routine,
        day: Date,
        logs: [DailyLog],
        calendar: Calendar,
        now: Date,
        isFutureDay: Bool
    ) -> HistoryDayRoutineRow {
        let dayLogs = logs.filter { calendar.isDate($0.date, inSameDayAs: day) }
        let log = dayLogs.first { $0.routineId == routine.id }
        let completed = log?.completedItems.count ?? 0
        let total = routine.items.count

        let timeDF = DateFormatter()
        timeDF.locale = Locale(identifier: "ko_KR")
        timeDF.dateFormat = "a h:mm"
        let startText = timeDF.string(from: routine.startTime)
        let subtitle = RoutineSchedule.cardSubtitle(
            for: routine,
            itemCount: total,
            startTimeText: startText
        )

        let status: HistoryDayRoutineStatus
        if RoutineDeadline.isFullyComplete(routine, logs: logs, day: day, calendar: calendar) {
            status = .completed
        } else if isFutureDay {
            status = .upcoming
        } else if isRoutineMissed(routine, logs: logs, day: day, calendar: calendar, now: now) {
            status = .missed
        } else if completed > 0 {
            status = .partial
        } else {
            status = .waiting
        }

        return HistoryDayRoutineRow(
            id: routine.id,
            name: routine.name,
            icon: routine.items.first?.icon ?? "list.bullet",
            subtitle: subtitle,
            completedCount: completed,
            totalCount: total,
            status: status
        )
    }

    private static func isRoutineMissed(
        _ routine: Routine,
        logs: [DailyLog],
        day: Date,
        calendar: Calendar,
        now: Date
    ) -> Bool {
        if RoutineDeadline.isFullyComplete(routine, logs: logs, day: day, calendar: calendar) {
            return false
        }
        let dayStart = calendar.startOfDay(for: day)
        let todayStart = calendar.startOfDay(for: now)
        if dayStart < todayStart { return true }
        if dayStart > todayStart { return false }
        if let end = RoutineDeadline.endTimeToday(for: routine, now: day, calendar: calendar) {
            return now >= end
        }
        return false
    }
}

struct HistoryDayDetailSheet: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    let snapshot: HistoryDaySnapshot

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    dayStatusBanner

                    if snapshot.isRestDay {
                        infoCard(
                            icon: "moon.zzz.fill",
                            text: AppCopy.History.dayDetailRest
                        )
                    } else if snapshot.isFuture && snapshot.routines.isEmpty {
                        infoCard(
                            icon: "calendar",
                            text: AppCopy.History.dayDetailFuture
                        )
                    } else if snapshot.routines.isEmpty {
                        infoCard(
                            icon: "calendar.badge.minus",
                            text: AppCopy.History.dayDetailNoSchedule
                        )
                    } else {
                        if snapshot.isFuture {
                            infoCard(
                                icon: "calendar",
                                text: AppCopy.History.dayDetailFuture
                            )
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text(AppCopy.History.dayDetailRoutines)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.anchorSub(scheme))

                            AnchorCard {
                                VStack(spacing: 0) {
                                    ForEach(snapshot.routines) { row in
                                        routineRowView(row)
                                        if row.id != snapshot.routines.last?.id {
                                            Divider()
                                                .padding(.leading, 52)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding(.horizontal, AnchorLayout.screenHorizontal)
                .padding(.bottom, 24)
            }
            .anchorScreenBackground()
            .navigationTitle(snapshot.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppCopy.Common.cancel) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    private var dayStatusBanner: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor.opacity(0.35))
                .frame(width: 10, height: 10)
            Text(statusLabel)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.anchorText(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private var statusLabel: String {
        if snapshot.isRestDay { return AppCopy.History.dayDetailRest }
        switch snapshot.overallStatus {
        case .full: return AppCopy.History.legendFull
        case .missedDeadline: return AppCopy.History.legendMissed
        case .none:
            if snapshot.isFuture { return AppCopy.History.dayDetailFuture }
            if snapshot.routines.isEmpty { return AppCopy.History.dayDetailNoSchedule }
            return AppCopy.History.legendNone
        }
    }

    private var statusColor: Color {
        if snapshot.isRestDay { return Color.anchorSuccess(scheme) }
        switch snapshot.overallStatus {
        case .full: return Color.anchorSuccess(scheme)
        case .missedDeadline: return Color.anchorWarning(scheme)
        case .none: return Color.anchorSub(scheme)
        }
    }

    private func infoCard(icon: String, text: String) -> some View {
        AnchorCard {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.anchorAccent(scheme))
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Color.anchorSub(scheme))
                Spacer(minLength: 0)
            }
            .padding(AnchorLayout.cardPadding)
        }
    }

    private func routineRowView(_ row: HistoryDayRoutineRow) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.anchorSubBg(scheme))
                    .frame(width: 40, height: 40)
                Image(systemName: row.icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.anchorText(scheme))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(row.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.anchorText(scheme))

                Text(row.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.anchorSub(scheme))
                    .lineLimit(2)

                if row.totalCount > 0, row.status == .partial || row.status == .waiting {
                    Text(AppCopy.History.routineProgress(completed: row.completedCount, total: row.totalCount))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.anchorSub(scheme))
                }
            }

            Spacer(minLength: 8)

            Text(statusText(for: row.status))
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusForeground(for: row.status))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(statusBackground(for: row.status))
                .clipShape(Capsule())
        }
        .padding(.horizontal, AnchorLayout.cardPadding)
        .padding(.vertical, 12)
    }

    private func statusText(for status: HistoryDayRoutineStatus) -> String {
        switch status {
        case .completed: return AppCopy.History.routineCompleted
        case .partial: return AppCopy.History.routineInProgress
        case .missed: return AppCopy.History.routineMissed
        case .waiting: return AppCopy.History.routineWaiting
        case .upcoming: return AppCopy.History.routineUpcoming
        }
    }

    private func statusForeground(for status: HistoryDayRoutineStatus) -> Color {
        switch status {
        case .completed: return Color.anchorSuccess(scheme)
        case .partial: return Color.anchorAccent(scheme)
        case .missed: return Color.anchorWarning(scheme)
        case .waiting, .upcoming: return Color.anchorSub(scheme)
        }
    }

    private func statusBackground(for status: HistoryDayRoutineStatus) -> Color {
        switch status {
        case .completed: return Color.anchorSuccess(scheme).opacity(0.15)
        case .partial: return Color.anchorAccent(scheme).opacity(0.12)
        case .missed: return Color.anchorWarning(scheme).opacity(0.18)
        case .waiting, .upcoming: return Color.anchorSubBg(scheme)
        }
    }
}
