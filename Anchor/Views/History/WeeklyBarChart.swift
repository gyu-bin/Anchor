//
//  WeeklyBarChart.swift
//  Anchor
//

import Charts
import SwiftUI

enum WeekdayCompletion: String, CaseIterable {
    case full
    case partial
    case none
}

struct WeekdayBar: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let status: WeekdayCompletion
}

struct WeeklyBarChart: View {
    @Environment(\.colorScheme) private var scheme

    let bars: [WeekdayBar]

    var body: some View {
        Chart(bars) { bar in
            BarMark(
                x: .value("요일", bar.label),
                y: .value("진행", bar.value)
            )
            .foregroundStyle(color(for: bar.status))
            .cornerRadius(6)
        }
        .chartYScale(domain: 0...3)
        .chartYAxis(.hidden)
        .frame(height: 160)
        .padding(.vertical, 6)
    }

    private func color(for status: WeekdayCompletion) -> Color {
        switch status {
        case .full:
            return Color.anchorSuccess
        case .partial:
            return Color.yellow
        case .none:
            return Color.anchorSub(scheme).opacity(0.35)
        }
    }
}

#Preview {
    WeeklyBarChart(bars: [
        WeekdayBar(label: "월", value: 3, status: .full),
        WeekdayBar(label: "화", value: 2, status: .partial),
        WeekdayBar(label: "수", value: 0.8, status: .none),
        WeekdayBar(label: "목", value: 3, status: .full),
        WeekdayBar(label: "금", value: 2, status: .partial),
        WeekdayBar(label: "토", value: 1, status: .none),
        WeekdayBar(label: "일", value: 3, status: .full),
    ])
    .padding()
}
