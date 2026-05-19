//
//  AppStoreScreenshotData.swift
//  Anchor
//

import Foundation
import SwiftData

/// App Store Connect 6.9" (iPhone 16 Pro Max) 논리 해상도.
enum AppStoreScreenshotData {
    static let exportWidth: CGFloat = 440
    static let exportHeight: CGFloat = 956
    static let exportScale: CGFloat = 3

    struct Seed {
        let container: ModelContainer
        let primaryRoutineID: UUID
    }

    @MainActor
    static func makeSeed() throws -> Seed {
        let schema = Schema([Routine.self, RoutineItem.self, DailyLog.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = container.mainContext
        let cal = Calendar.current
        let today = Date().startOfDay(in: cal)

        var morningDraft = RoutineScheduleDraft()
        morningDraft.kind = .daily
        morningDraft.startTime = cal.date(bySettingHour: 7, minute: 0, second: 0, of: today) ?? today

        let morning = Routine(name: "아침 루틴", startTime: morningDraft.startTime, order: 0)
        RoutineSchedule.apply(morningDraft, to: morning, calendar: cal)
        morning.blockedWebs = ["youtube.com", "instagram.com"]

        let read = RoutineItem(name: "독서 20분", duration: 20, icon: "book.fill", order: 0, routine: morning)
        let meditate = RoutineItem(name: "명상", duration: 10, icon: "brain.head.profile", order: 1, routine: morning)
        let water = RoutineItem(name: "물 한 잔", duration: 1, icon: "drop.fill", order: 2, routine: morning)
        morning.items = [read, meditate, water]

        var eveningDraft = RoutineScheduleDraft()
        eveningDraft.kind = .daily
        eveningDraft.startTime = cal.date(bySettingHour: 21, minute: 30, second: 0, of: today) ?? today

        let evening = Routine(name: "저녁 마무리", startTime: eveningDraft.startTime, order: 1)
        RoutineSchedule.apply(eveningDraft, to: evening, calendar: cal)
        evening.blockedWebs = ["netflix.com"]

        let tidy = RoutineItem(name: "방 정리", duration: 15, icon: "house.fill", order: 0, routine: evening)
        let journal = RoutineItem(name: "하루 일기", duration: 10, icon: "square.and.pencil", order: 1, routine: evening)
        evening.items = [tidy, journal]

        ctx.insert(morning)
        ctx.insert(evening)
        ctx.insert(read)
        ctx.insert(meditate)
        ctx.insert(water)
        ctx.insert(tidy)
        ctx.insert(journal)

        let todayLog = DailyLog(
            date: today,
            routineId: morning.id,
            completedItems: [read.id, meditate.id],
            isFullyCompleted: false,
            totalMinutes: 30
        )
        ctx.insert(todayLog)

        for offset in 1...21 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let dayStart = day.startOfDay(in: cal)
            let full = offset % 5 != 0
            let log = DailyLog(
                date: dayStart,
                routineId: morning.id,
                completedItems: full ? morning.items.map(\.id) : [read.id],
                isFullyCompleted: full,
                totalMinutes: full ? 31 : 20
            )
            ctx.insert(log)
        }

        try ctx.save()
        return Seed(container: container, primaryRoutineID: morning.id)
    }
}
