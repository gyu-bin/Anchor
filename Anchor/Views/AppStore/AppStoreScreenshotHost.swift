//
//  AppStoreScreenshotHost.swift
//  Anchor
//

import SwiftData
import SwiftUI

/// App Store 캡처·ImageRenderer용 — 가이드·탭 UI만 표시합니다.
struct AppStoreScreenshotHost: View {
    enum Screen: String, CaseIterable {
        case today
        case routine
        case guideMorning
        case guideEvening
        case guideRelief
        case guideHow
        case history
        case settingsScreenTime
        case settings
        case paywall
        case guideNotification
        case guideStart
        case splash
    }

    let screen: Screen
    let expandedRoutineIDs: Set<UUID>

    @State private var selectedTab: Int
    @State private var tabRouter = TabRouter()
    @State private var routineViewModel = RoutineViewModel()
    @StateObject private var premiumStore = PremiumStore()

    init(screen: Screen, expandedRoutineIDs: Set<UUID>) {
        self.screen = screen
        self.expandedRoutineIDs = expandedRoutineIDs
        _selectedTab = State(initialValue: screen.tabIndex)
    }

    var body: some View {
        Group {
            switch screen {
            case .guideMorning:
                AppGuideView(initialPage: 0, onFinish: {})
            case .guideEvening:
                AppGuideView(initialPage: 1, onFinish: {})
            case .guideRelief:
                AppGuideView(initialPage: 2, onFinish: {})
            case .guideHow:
                AppGuideView(initialPage: 3, onFinish: {})
            case .guideNotification:
                AppGuideView(initialPage: 5, onFinish: {})
            case .guideStart:
                AppGuideView(initialPage: 6, onFinish: {})
            case .paywall:
                PaywallSheet(reason: .general)
                    .environmentObject(premiumStore)
            case .splash:
                SplashStaticView()
            default:
                tabShell
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            tabRouter.selectedTab = selectedTab
        }
    }

    private var tabShell: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { SwiftUI.Label("오늘", systemImage: "sun.max.fill") }
                .tag(0)

            RoutineView()
                .tabItem { SwiftUI.Label("루틴", systemImage: "list.bullet.rectangle.fill") }
                .tag(1)
                .environment(\.appStoreScreenshotExpandedRoutines, expandedRoutineIDs)

            HistoryView()
                .tabItem { SwiftUI.Label("기록", systemImage: "chart.bar.fill") }
                .tag(2)

            SettingsView()
                .tabItem { SwiftUI.Label("설정", systemImage: "gearshape.fill") }
                .tag(3)
                .environment(
                    \.appStoreScreenshotExpandScreenTime,
                    screen == .settingsScreenTime
                )
        }
        .tint(Color("AnchorAccent"))
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .environment(routineViewModel)
        .environmentObject(tabRouter)
        .environmentObject(premiumStore)
    }
}

private extension AppStoreScreenshotHost.Screen {
    var tabIndex: Int {
        switch self {
        case .today, .splash: 0
        case .routine: 1
        case .history: 2
        case .settings, .settingsScreenTime: 3
        default: 0
        }
    }
}

#if DEBUG
#Preview("Today") {
    let seed = try! AppStoreScreenshotData.makeSeed()
    AppStoreScreenshotHost(screen: .today, expandedRoutineIDs: [])
        .modelContainer(seed.container)
}

#Preview("Routine") {
    let seed = try! AppStoreScreenshotData.makeSeed()
    AppStoreScreenshotHost(screen: .routine, expandedRoutineIDs: [seed.primaryRoutineID])
        .modelContainer(seed.container)
}
#endif
