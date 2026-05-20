//
//  AppearanceSettings.swift
//  Anchor
//

import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    /// 앱 기본값 — 시스템 다크 여부와 무관하게 첫 실행은 라이트
    static let defaultMode: AppearanceMode = .light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "시스템"
        case .light: return "라이트"
        case .dark: return "다크"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AppGuideStorage {
    static let hasSeenGuideKey = "hasSeenAppGuide"
}
