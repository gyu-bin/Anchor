//
//  SharedShieldStore.swift
//  Anchor
//

import FamilyControls
import Foundation

struct ScheduledRoutineShield: Codable {
    let routineId: UUID
    let startHour: Int
    let startMinute: Int
    let isComplete: Bool
    let selectionData: Data
    /// nil이면 완료할 때까지 잠금. 있으면 해당 시각 이후 미완료여도 잠금 해제.
    let unlockHour: Int?
    let unlockMinute: Int?

    init(
        routineId: UUID,
        startHour: Int,
        startMinute: Int,
        isComplete: Bool,
        selectionData: Data,
        unlockHour: Int? = nil,
        unlockMinute: Int? = nil
    ) {
        self.routineId = routineId
        self.startHour = startHour
        self.startMinute = startMinute
        self.isComplete = isComplete
        self.selectionData = selectionData
        self.unlockHour = unlockHour
        self.unlockMinute = unlockMinute
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        routineId = try c.decode(UUID.self, forKey: .routineId)
        startHour = try c.decode(Int.self, forKey: .startHour)
        startMinute = try c.decode(Int.self, forKey: .startMinute)
        isComplete = try c.decode(Bool.self, forKey: .isComplete)
        selectionData = try c.decode(Data.self, forKey: .selectionData)
        unlockHour = try c.decodeIfPresent(Int.self, forKey: .unlockHour)
        unlockMinute = try c.decodeIfPresent(Int.self, forKey: .unlockMinute)
    }

    private enum CodingKeys: String, CodingKey {
        case routineId, startHour, startMinute, isComplete, selectionData, unlockHour, unlockMinute
    }
}

/// App Group — Device Activity 확장·메인 앱 공유.
enum SharedShieldStore {
    static let appGroupID = "group.com.rbqls6651.anchor"
    static let mergedSelectionKey = "mergedShieldSelection"
    static let scheduleKey = "scheduledRoutineShields"
    static let blockedWebDomainsKey = "blockedWebDomains"

    static var suite: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func saveMergedSelection(_ selection: FamilyActivitySelection) {
        guard let data = try? PropertyListEncoder().encode(selection) else { return }
        suite?.set(data, forKey: mergedSelectionKey)
    }

    static func saveSchedule(_ items: [ScheduledRoutineShield]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        suite?.set(data, forKey: scheduleKey)
    }

    static func loadMergedSelection() -> FamilyActivitySelection {
        guard let data = suite?.data(forKey: mergedSelectionKey) else { return FamilyActivitySelection() }
        return (try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)) ?? FamilyActivitySelection()
    }

    static func clearMergedSelection() {
        suite?.removeObject(forKey: mergedSelectionKey)
    }

    static func saveBlockedWebDomainStrings(_ domains: [String]) {
        suite?.set(domains, forKey: blockedWebDomainsKey)
    }

    static func loadBlockedWebDomainStrings() -> [String] {
        suite?.stringArray(forKey: blockedWebDomainsKey) ?? []
    }

    static func clearSchedule() {
        suite?.removeObject(forKey: scheduleKey)
    }

    static func clearAll() {
        clearMergedSelection()
        clearSchedule()
        suite?.removeObject(forKey: blockedWebDomainsKey)
    }

}
