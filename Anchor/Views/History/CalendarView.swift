//
//  CalendarView.swift
//  Anchor
//

import SwiftUI

struct MonthDayDot: Identifiable {
    let id = UUID()
    let day: Int
    let status: WeekdayCompletion
}

struct CalendarMonthView: View {
    @Environment(\.colorScheme) private var scheme

    let monthTitle: String
    let daysInMonth: Int
    let firstWeekdayIndex: Int // 0 = Sunday ... (Calendar firstWeekday adjusted)
    let dayStatuses: [Int: WeekdayCompletion] // day number -> status

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdaySymbols: [String] = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(monthTitle)
                .font(.headline)
                .foregroundStyle(Color.anchorText(scheme))

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdaySymbols[i])
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.anchorSub(scheme))
                }

                ForEach(0..<leadingBlanks, id: \.self) { _ in
                    Color.clear.frame(height: 34)
                }

                ForEach(1...daysInMonth, id: \.self) { day in
                    VStack(spacing: 6) {
                        Text("\(day)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.anchorText(scheme))
                        Circle()
                            .fill(dotColor(day))
                            .frame(width: 6, height: 6)
                    }
                    .frame(height: 34)
                }
            }
        }
        .padding(14)
        .background(Color.anchorCard(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var leadingBlanks: Int {
        max(0, firstWeekdayIndex % 7)
    }

    private func dotColor(_ day: Int) -> Color {
        switch dayStatuses[day] ?? .none {
        case .full:
            return Color.anchorSuccess
        case .partial:
            return Color.yellow
        case .none:
            return Color.clear
        }
    }
}
