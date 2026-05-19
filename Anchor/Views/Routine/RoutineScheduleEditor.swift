//
//  RoutineScheduleEditor.swift
//  Anchor
//

import SwiftUI

/// iOS 설정 앱 스타일 — 한 그룹에 필요한 행만 표시
struct RoutineScheduleEditor: View {
    @Environment(\.colorScheme) private var scheme

    @Binding var draft: RoutineScheduleDraft

    private var periodRangeInvalid: Bool {
        draft.kind == .period
            && draft.scheduleStartDate.startOfDay() > draft.scheduleEndDate.startOfDay()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoutineFormInsetGroup {
                repeatRow

                switch draft.kind {
                case .daily:
                    repeatEndRows
                case .weekdays:
                    weekdayRow
                    repeatEndRows
                case .period:
                    periodDateRows
                    weekdayRow
                case .once:
                    onceDateRow
                }

            }

            RoutineFormInsetGroup {
                DatePicker(
                    AppCopy.Routine.startTimeLabel,
                    selection: $draft.startTime,
                    displayedComponents: .hourAndMinute
                )
                .environment(\.locale, Locale(identifier: "ko_KR"))
                .formRow()

                RoutineFormDivider()

                Toggle(AppCopy.Routine.endTimeToggle, isOn: $draft.hasEndTime)
                    .tint(Color.anchorAccent(scheme))
                    .formRow()

                if draft.hasEndTime {
                    RoutineFormDivider()
                    DatePicker(
                        AppCopy.Routine.endTimeLabel,
                        selection: $draft.endTime,
                        displayedComponents: .hourAndMinute
                    )
                    .environment(\.locale, Locale(identifier: "ko_KR"))
                    .formRow()
                }
            }

            if draft.hasEndTime {
                Text(AppCopy.Routine.endTimeNote)
                    .font(.caption)
                    .lineSpacing(2)
                    .foregroundStyle(Color.anchorSub(scheme))
            }

            if periodRangeInvalid {
                Text(AppCopy.Routine.periodRangeInvalid)
                    .font(.caption)
                    .foregroundStyle(Color.anchorAccent(scheme))
            } else if draft.kind == .weekdays, draft.activeWeekdays.isEmpty {
                Text(AppCopy.Routine.weekdayRequired)
                    .font(.caption)
                    .foregroundStyle(Color.anchorAccent(scheme))
            }
        }
    }

    // MARK: - 반복

    private var repeatRow: some View {
        HStack {
            Text(AppCopy.Routine.scheduleRowRepeat)
                .foregroundStyle(Color.anchorText(scheme))
            Spacer(minLength: 8)
            Picker("", selection: $draft.kind) {
                ForEach(RoutineScheduleKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(Color.anchorSub(scheme))
        }
        .formRow()
        .onChange(of: draft.kind) { _, newKind in
            applyKindDefaults(newKind)
        }
    }

    private var repeatEndRows: some View {
        Group {
            RoutineFormDivider()
            Toggle(AppCopy.Routine.scheduleRowEnd, isOn: $draft.hasScheduleEnd)
                .tint(Color.anchorAccent(scheme))
                .formRow()
            if draft.hasScheduleEnd {
                RoutineFormDivider()
                DatePicker(
                    AppCopy.Routine.scheduleEndLabel,
                    selection: $draft.scheduleEndDate,
                    in: Date().startOfDay()...,
                    displayedComponents: .date
                )
                .environment(\.locale, Locale(identifier: "ko_KR"))
                .formRow()
            }
        }
    }

    private var periodDateRows: some View {
        Group {
            RoutineFormDivider()
            DatePicker(
                AppCopy.Routine.scheduleStartLabel,
                selection: $draft.scheduleStartDate,
                displayedComponents: .date
            )
            .environment(\.locale, Locale(identifier: "ko_KR"))
            .formRow()

            RoutineFormDivider()
            DatePicker(
                AppCopy.Routine.scheduleEndLabel,
                selection: $draft.scheduleEndDate,
                in: draft.scheduleStartDate.startOfDay()...,
                displayedComponents: .date
            )
            .environment(\.locale, Locale(identifier: "ko_KR"))
            .formRow()
        }
    }

    private var onceDateRow: some View {
        Group {
            RoutineFormDivider()
            DatePicker(
                AppCopy.Routine.onceDateLabel,
                selection: $draft.oneTimeDate,
                displayedComponents: .date
            )
            .environment(\.locale, Locale(identifier: "ko_KR"))
            .formRow()
        }
    }

    private var weekdayRow: some View {
        Group {
            RoutineFormDivider()
            VStack(alignment: .leading, spacing: 10) {
                Text(AppCopy.Routine.scheduleRowWeekdays)
                    .font(.body)
                    .foregroundStyle(Color.anchorText(scheme))
                HStack(spacing: 6) {
                    ForEach(RoutineSchedule.weekdayOptions, id: \.0) { weekday, label in
                        weekdayChip(weekday: weekday, label: label)
                    }
                }
            }
            .formRow()
        }
    }

    private func weekdayChip(weekday: Int, label: String) -> some View {
        let on = draft.activeWeekdays.contains(weekday)
        return Button {
            if on {
                draft.activeWeekdays.remove(weekday)
            } else {
                draft.activeWeekdays.insert(weekday)
            }
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(on ? Color.anchorAccent(scheme).opacity(0.18) : Color.anchorCard(scheme))
                .foregroundStyle(on ? Color.anchorAccent(scheme) : Color.anchorSub(scheme))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func applyKindDefaults(_ newKind: RoutineScheduleKind) {
        switch newKind {
        case .weekdays:
            if draft.activeWeekdays.isEmpty {
                draft.activeWeekdays = RoutineSchedule.weekdaySet
            }
        case .period:
            let range = RoutineSchedule.thisWeekRange()
            draft.scheduleStartDate = range.start
            draft.scheduleEndDate = range.end
        case .daily:
            draft.hasScheduleEnd = false
        case .once:
            break
        }
    }
}

private extension View {
    func formRow() -> some View {
        padding(.horizontal, 14)
            .padding(.vertical, 11)
    }
}
