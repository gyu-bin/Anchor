//
//  DeviceActivityMonitorExtension.swift
//  AnchorDeviceActivityMonitor
//

import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        applyActiveShieldsFromAppGroup()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
    }

    private func applyActiveShieldsFromAppGroup() {
        let selection = SharedShieldStoreAppGroup.activeSelection(at: Date())
        if selection.applicationTokens.isEmpty {
            store.shield.applications = nil
        } else {
            store.shield.applications = selection.applicationTokens
        }

        let domainStrings = SharedShieldStoreAppGroup.loadBlockedWebDomainStrings()
        DeviceActivityWebBlocking.apply(
            to: store,
            webTokens: selection.webDomainTokens,
            domainStrings: domainStrings
        )
    }
}

private enum DeviceActivityWebBlocking {
    static func apply(
        to store: ManagedSettingsStore,
        webTokens: Set<WebDomainToken>,
        domainStrings: [String]
    ) {
        var managed = Set<WebDomain>()
        for raw in domainStrings {
            let base = raw
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
                .split(separator: "/").first.map(String.init) ?? ""
            guard !base.isEmpty else { continue }
            managed.insert(WebDomain(domain: base))
            if !base.hasPrefix("www.") {
                managed.insert(WebDomain(domain: "www.\(base)"))
            }
            if base == "youtube.com" {
                managed.insert(WebDomain(domain: "m.youtube.com"))
                managed.insert(WebDomain(domain: "youtu.be"))
            }
        }

        store.shield.webDomains = webTokens.isEmpty ? nil : webTokens
        store.webContent.blockedByFilter = managed.isEmpty ? .none : .specific(managed)
    }
}

struct ScheduledRoutineShield: Codable {
    let routineId: UUID
    let startHour: Int
    let startMinute: Int
    let isComplete: Bool
    let selectionData: Data
}

enum SharedShieldStoreAppGroup {
    static let id = "group.com.rbqls6651.anchor"
    static let mergedSelectionKey = "mergedShieldSelection"
    static let scheduleKey = "scheduledRoutineShields"
    static let blockedWebDomainsKey = "blockedWebDomains"

    static func activeSelection(at now: Date) -> FamilyActivitySelection {
        guard let items = loadSchedule(), !items.isEmpty else {
            return loadMergedSelection()
        }

        let calendar = Calendar.current
        var merge = FamilyActivitySelection()

        for item in items where !item.isComplete {
            guard hasStarted(item: item, now: now, calendar: calendar) else { continue }
            let selection = (try? PropertyListDecoder().decode(
                FamilyActivitySelection.self,
                from: item.selectionData
            )) ?? FamilyActivitySelection()
            merge.applicationTokens.formUnion(selection.applicationTokens)
            merge.webDomainTokens.formUnion(selection.webDomainTokens)
        }

        return merge
    }

    private static func hasStarted(item: ScheduledRoutineShield, now: Date, calendar: Calendar) -> Bool {
        guard let startToday = calendar.date(
            bySettingHour: item.startHour,
            minute: item.startMinute,
            second: 0,
            of: calendar.startOfDay(for: now)
        ) else { return true }
        return now >= startToday
    }

    private static func loadSchedule() -> [ScheduledRoutineShield]? {
        guard let data = UserDefaults(suiteName: id)?.data(forKey: scheduleKey) else { return nil }
        return try? JSONDecoder().decode([ScheduledRoutineShield].self, from: data)
    }

    static func loadBlockedWebDomainStrings() -> [String] {
        UserDefaults(suiteName: id)?.stringArray(forKey: blockedWebDomainsKey) ?? []
    }

    private static func loadMergedSelection() -> FamilyActivitySelection {
        guard let data = UserDefaults(suiteName: id)?.data(forKey: mergedSelectionKey) else {
            return FamilyActivitySelection()
        }
        return (try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data))
            ?? FamilyActivitySelection()
    }
}
