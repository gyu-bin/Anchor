//
//  CalendarView.swift
//  Anchor
//

import SwiftUI

private enum CalendarGridCell: Identifiable {
    case weekday(String)
    case blank(Int)
    case day(Int)

    var id: String {
        switch self {
        case .weekday(let label):
            return "weekday-\(label)"
        case .blank(let index):
            return "blank-\(index)"
        case .day(let number):
            return "day-\(number)"
        }
    }
}

struct CalendarMonthView: View {
    @Environment(\.colorScheme) private var scheme

    let monthTitle: String
    let daysInMonth: Int
    let firstWeekdayIndex: Int
    let dayStatuses: [Int: WeekdayCompletion]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols: [String] = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(monthTitle)
                .font(AnchorTypography.cardTitle(scheme))
                .foregroundStyle(Color.anchorText(scheme))

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(gridCells) { cell in
                    switch cell {
                    case .weekday(let label):
                        Text(label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.anchorSub(scheme))
                            .frame(height: 28)
                    case .blank:
                        Color.clear.frame(height: 36)
                    case .day(let day):
                        dayCell(day)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ day: Int) -> some View {
        let status = dayStatuses[day] ?? .none
        let isToday = Calendar.current.isDateInToday(dayDate(day))

        VStack(spacing: 4) {
            Text("\(day)")
                .font(.system(size: 13, weight: isToday ? .bold : .medium))
                .foregroundStyle(dayTextColor(status: status, isToday: isToday))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background(dayBackground(status: status, isToday: isToday))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func dayDate(_ day: Int) -> Date {
        let cal = Calendar.current
        let now = Date()
        var comps = cal.dateComponents([.year, .month], from: now)
        comps.day = day
        return cal.date(from: comps) ?? now
    }

    private func dayTextColor(status: WeekdayCompletion, isToday: Bool) -> Color {
        if isToday { return Color.anchorAccent(scheme) }
        switch status {
        case .full, .partial:
            return Color.anchorText(scheme)
        case .none:
            return Color.anchorSub(scheme)
        }
    }

    private func dayBackground(status: WeekdayCompletion, isToday: Bool) -> Color {
        if isToday {
            return Color.anchorAccent(scheme).opacity(0.12)
        }
        switch status {
        case .full:
            return Color.anchorSuccess(scheme).opacity(0.18)
        case .partial:
            return Color.anchorAccent(scheme).opacity(0.12)
        case .none:
            return Color.clear
        }
    }

    private var leadingBlanks: Int {
        max(0, firstWeekdayIndex % 7)
    }

    private var gridCells: [CalendarGridCell] {
        var cells: [CalendarGridCell] = weekdaySymbols.map { .weekday($0) }
        cells += (0..<leadingBlanks).map { .blank($0) }
        cells += (1...daysInMonth).map { .day($0) }
        return cells
    }
}
