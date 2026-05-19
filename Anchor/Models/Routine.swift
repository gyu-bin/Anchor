//
//  Routine.swift
//  Anchor
//

import Foundation
import SwiftData

@Model
final class Routine {
    var id: UUID
    var name: String
    var startTime: Date
    var order: Int
    @Relationship(deleteRule: .cascade, inverse: \RoutineItem.routine)
    var items: [RoutineItem]
    var blockedApps: [String]
    var blockedWebs: [String]
    /// `FamilyActivitySelection` PropertyList 인코딩 (차단할 앱 토큰).
    var shieldSelectionData: Data?

    /// `RoutineScheduleKind` raw value (마이그레이션 호환을 위해 optional)
    var scheduleKindRaw: String?
    /// `Calendar.weekday` 1=일 … 7=토 (마이그레이션 호환을 위해 optional)
    var activeWeekdays: [Int]?
    /// `once` 일정의 당일 0시
    var oneTimeDate: Date?
    /// 일정 시작일 0시 (`period`·제한 기간)
    var scheduleStartDate: Date?
    /// 일정 종료일 0시 (inclusive)
    var scheduleEndDate: Date?
    /// `RoutineExpiryAction` raw
    var expiryActionRaw: String?
    /// 만료 후 목록에서 숨김
    var isArchived: Bool?
    /// 루틴 종료 시간 (nil = 설정 안함)
    var endTime: Date?
    /// 루틴을 만든 날(기록·달력에서 이전 날짜는 미완료로 치지 않음)
    var createdAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        startTime: Date,
        order: Int = 0,
        items: [RoutineItem] = [],
        blockedApps: [String] = [],
        blockedWebs: [String] = [],
        shieldSelectionData: Data? = nil,
        scheduleKindRaw: String? = RoutineScheduleKind.daily.rawValue,
        activeWeekdays: [Int]? = Array(1...7),
        oneTimeDate: Date? = nil,
        scheduleStartDate: Date? = nil,
        scheduleEndDate: Date? = nil,
        expiryActionRaw: String? = nil,
        isArchived: Bool? = false
    ) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.order = order
        self.items = items
        self.blockedApps = blockedApps
        self.blockedWebs = blockedWebs
        self.shieldSelectionData = shieldSelectionData
        self.scheduleKindRaw = scheduleKindRaw
        self.activeWeekdays = activeWeekdays
        self.oneTimeDate = oneTimeDate
        self.scheduleStartDate = scheduleStartDate
        self.scheduleEndDate = scheduleEndDate
        self.expiryActionRaw = expiryActionRaw
        self.isArchived = isArchived
        self.createdAt = Date()
    }
}
