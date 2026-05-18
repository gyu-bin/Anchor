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
    static let shieldTitleKey = "shield.title"
    static let shieldSubtitleKey = "shield.subtitle"

    static let defaultShieldTitle = "루틴을 먼저 완료해 주세요"
    static let defaultShieldSubtitle = "끝나면 바로 열어 드릴게요"

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

    static func clearSchedule() {
        suite?.removeObject(forKey: scheduleKey)
    }

    static func clearAll() {
        clearMergedSelection()
        clearSchedule()
    }

    static var shieldTitle: String {
        let value = suite?.string(forKey: shieldTitleKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (value?.isEmpty == false) ? value! : defaultShieldTitle
    }

    static var shieldSubtitle: String {
        let value = suite?.string(forKey: shieldSubtitleKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (value?.isEmpty == false) ? value! : defaultShieldSubtitle
    }

    static func saveShieldMessages(title: String, subtitle: String) {
        suite?.set(title, forKey: shieldTitleKey)
        suite?.set(subtitle, forKey: shieldSubtitleKey)
    }
}
