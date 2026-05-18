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
            .cornerRadius(8)
        }
        .chartYScale(domain: 0...3)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.anchorSub(scheme))
                    }
                }
            }
        }
        .frame(height: 148)
        .padding(.top, 4)
    }

    private func color(for status: WeekdayCompletion) -> Color {
        switch status {
        case .full:
            return Color.anchorSuccess(scheme)
        case .partial:
            return Color.anchorAccent(scheme).opacity(0.65)
        case .none:
            return Color.anchorSubBg(scheme)
        }
    }
}
