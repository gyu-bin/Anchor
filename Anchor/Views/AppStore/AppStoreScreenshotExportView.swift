//
//  AppStoreScreenshotExportView.swift
//  Anchor
//

import SwiftData
import SwiftUI

/// 시뮬레이터 `-ExportAppStoreScreenshots <screen>` — 해당 탭 UI (외부 `simctl io` 캡처용).
struct AppStoreScreenshotExportView: View {
    let screen: AppStoreScreenshotHost.Screen
    let seed: AppStoreScreenshotData.Seed

    init(screen: AppStoreScreenshotHost.Screen) {
        self.screen = screen
        UserDefaults.standard.set(true, forKey: AppGuideStorage.hasSeenGuideKey)
        PremiumStorage.setPremium(true)
        guard let made = try? AppStoreScreenshotData.makeSeed() else {
            fatalError("AppStoreScreenshotData.makeSeed failed")
        }
        seed = made
    }

    var body: some View {
        AppStoreScreenshotHost(
            screen: screen,
            expandedRoutineIDs: screen == .routine ? [seed.primaryRoutineID] : []
        )
        .modelContainer(seed.container)
        .preferredColorScheme(.light)
    }
}

enum AppStoreScreenshotLaunch {
    static let flag = "-ExportAppStoreScreenshots"

    static var screen: AppStoreScreenshotHost.Screen? {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: flag), idx + 1 < args.count else { return nil }
        return AppStoreScreenshotHost.Screen(rawValue: args[idx + 1])
    }

    static var isActive: Bool { screen != nil }
}
