//
//  AppStoreScreenshotEnvironment.swift
//  Anchor
//

import SwiftUI

private struct AppStoreScreenshotExpandedRoutinesKey: EnvironmentKey {
    static let defaultValue: Set<UUID>? = nil
}

extension EnvironmentValues {
    /// 스토어 스크린샷용 — 루틴 탭에서 펼칠 카드 ID.
    var appStoreScreenshotExpandedRoutines: Set<UUID>? {
        get { self[AppStoreScreenshotExpandedRoutinesKey.self] }
        set { self[AppStoreScreenshotExpandedRoutinesKey.self] = newValue }
    }
}

private struct AppStoreScreenshotExpandScreenTimeKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// 스토어 스크린샷용 — 설정에서 Screen Time 섹션 펼침.
    var appStoreScreenshotExpandScreenTime: Bool {
        get { self[AppStoreScreenshotExpandScreenTimeKey.self] }
        set { self[AppStoreScreenshotExpandScreenTimeKey.self] = newValue }
    }
}
