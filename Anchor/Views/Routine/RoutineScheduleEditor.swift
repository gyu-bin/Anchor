//
//  RoutineScheduleEditor.swift
//  Anchor
//

import SwiftUI

struct RoutineScheduleEditor: View {
    @Environment(\.colorScheme) private var scheme

    @Binding var draft: RoutineScheduleDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppCopy.Routine.scheduleSection)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.anchorSub(scheme))

            Picker(AppCopy.Routine.scheduleSection, selection: $draft.kind) {
                ForEach(RoutineScheduleKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            switch draft.kind {
            case .daily:
                Text(AppCopy.Routine.ScheduleKind.dailyNote)
                    .font(.caption)
                    .foregroundStyle(Color.anchorSub(scheme))
            case .weekdays:
                weekdayPicker
            case .once:
                onceSection
            }

            DatePicker(
                AppCopy.Routine.startTimeLabel,
                selection: $draft.startTime,
                displayedComponents: .hourAndMinute
            )
            .environment(\.locale, Locale(identifier: "ko_KR"))
        }
    }

    private var weekdayPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppCopy.Routine.weekdaySelect)
                .font(.caption)
                .foregroundStyle(Color.anchorSub(scheme))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(RoutineSchedule.weekdayOptions, id: \.0) { weekday, label in
                    let on = draft.activeWeekdays.contains(weekday)
                    Button {
                        if on {
                            draft.activeWeekdays.remove(weekday)
                        } else {
                            draft.activeWeekdays.insert(weekday)
                        }
                    } label: {
                        Text(label)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(on ? Color.anchorAccent(scheme).opacity(0.15) : Color.anchorSubBg(scheme))
                            .foregroundStyle(on ? Color.anchorAccent(scheme) : Color.anchorText(scheme))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(on ? Color.anchorAccent(scheme).opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var onceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppCopy.Routine.ScheduleKind.onceNote)
                .font(.caption)
                .foregroundStyle(Color.anchorSub(scheme))
            DatePicker(
                AppCopy.Routine.onceDateLabel,
                selection: $draft.oneTimeDate,
                displayedComponents: .date
            )
            .environment(\.locale, Locale(identifier: "ko_KR"))
            Button(AppCopy.Routine.onceToday) {
                draft.oneTimeDate = Date()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.anchorAccent(scheme))
        }
    }
}
