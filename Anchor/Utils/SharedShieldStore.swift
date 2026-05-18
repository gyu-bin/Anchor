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
