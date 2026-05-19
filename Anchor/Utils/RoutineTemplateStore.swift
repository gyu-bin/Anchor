//
//  RoutineTemplateStore.swift
//  Anchor
//

import Foundation
import SwiftData

@MainActor
enum RoutineTemplateStore {
    private static let maxTemplates = 30

    static func save(from routine: Routine, context: ModelContext) {
        let blockedWebs = routine.resolvedBlockedWebs(in: context)
        let items = routine.items.sorted { $0.order < $1.order }.map { item in
            RoutineTemplateItem(
                name: item.name,
                duration: item.duration,
                icon: item.icon,
                order: item.order
            )
        }
        let template = RoutineTemplate(
            name: routine.name,
            scheduleKindRaw: routine.scheduleKindRaw ?? RoutineScheduleKind.daily.rawValue,
            activeWeekdays: routine.activeWeekdays,
            oneTimeDate: routine.oneTimeDate,
            scheduleStartDate: routine.scheduleStartDate,
            scheduleEndDate: routine.scheduleEndDate,
            startTime: routine.startTime,
            endTime: routine.endTime,
            blockedApps: routine.blockedApps,
            blockedWebs: blockedWebs,
            shieldSelectionData: routine.shieldSelectionData,
            items: items
        )
        for item in items {
            item.template = template
            context.insert(item)
        }
        context.insert(template)
        prune(context: context)
    }

    static func sortedTemplates(context: ModelContext) -> [RoutineTemplate] {
        let fd = FetchDescriptor<RoutineTemplate>(
            sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
        )
        return (try? context.fetch(fd)) ?? []
    }

    @discardableResult
    static func createRoutine(
        from template: RoutineTemplate,
        context: ModelContext,
        routines: [Routine],
        order: Int
    ) -> Routine {
        var draft = draftForNewRoutine(from: template)
        let routine = Routine(
            name: template.name,
            startTime: draft.startTime,
            order: order,
            blockedApps: template.blockedApps,
            blockedWebs: template.blockedWebs,
            shieldSelectionData: template.shieldSelectionData
        )
        routine.endTime = template.endTime
        RoutineSchedule.apply(draft, to: routine)
        context.insert(routine)

        for item in template.items.sorted(by: { $0.order < $1.order }) {
            let newItem = RoutineItem(
                name: item.name,
                duration: item.duration,
                icon: item.icon,
                order: item.order,
                routine: routine
            )
            context.insert(newItem)
            routine.items.append(newItem)
        }
        return routine
    }

    /// 불러올 때는 날짜만 오늘·이번 주 기준으로 맞춥니다.
    static func draftForNewRoutine(from template: RoutineTemplate, calendar: Calendar = .current) -> RoutineScheduleDraft {
        var draft = RoutineScheduleDraft()
        let kind = RoutineScheduleKind(rawValue: template.scheduleKindRaw) ?? .daily
        draft.kind = kind
        draft.startTime = template.startTime
        draft.hasEndTime = template.endTime != nil
        draft.endTime = template.endTime ?? draft.startTime
        draft.activeWeekdays = Set(template.activeWeekdays ?? [])

        switch kind {
        case .daily:
            draft.hasScheduleEnd = false
        case .weekdays:
            if draft.activeWeekdays.isEmpty {
                draft.activeWeekdays = RoutineSchedule.weekdaySet
            }
            draft.hasScheduleEnd = false
        case .period:
            let range = RoutineSchedule.thisWeekRange(calendar: calendar)
            draft.scheduleStartDate = range.start
            draft.scheduleEndDate = range.end
        case .once:
            draft.oneTimeDate = Date()
        }
        return draft
    }

    static func subtitle(for template: RoutineTemplate) -> String {
        let fake = Routine(
            name: template.name,
            startTime: template.startTime,
            scheduleKindRaw: template.scheduleKindRaw,
            activeWeekdays: template.activeWeekdays,
            oneTimeDate: template.oneTimeDate,
            scheduleStartDate: template.scheduleStartDate,
            scheduleEndDate: template.scheduleEndDate
        )
        fake.endTime = template.endTime
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "a h:mm"
        return RoutineSchedule.cardSubtitle(
            for: fake,
            itemCount: template.items.count,
            startTimeText: df.string(from: template.startTime)
        )
    }

    private static func prune(context: ModelContext) {
        let all = sortedTemplates(context: context)
        guard all.count > maxTemplates else { return }
        for template in all.dropFirst(maxTemplates) {
            context.delete(template)
        }
    }
}
