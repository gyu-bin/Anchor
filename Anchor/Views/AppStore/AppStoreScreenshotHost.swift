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
        case history
        case settings
        case guide
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
            case .guide:
                AppGuideView(onFinish: {})
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
                .tabItem { Label("오늘", systemImage: "sun.max.fill") }
                .tag(0)

            RoutineView()
                .tabItem { Label("루틴", systemImage: "list.bullet.rectangle.fill") }
                .tag(1)
                .environment(\.appStoreScreenshotExpandedRoutines, expandedRoutineIDs)

            HistoryView()
                .tabItem { Label("기록", systemImage: "chart.bar.fill") }
                .tag(2)

            SettingsView()
                .tabItem { Label("설정", systemImage: "gearshape.fill") }
                .tag(3)
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
        case .today: 0
        case .routine: 1
        case .history: 2
        case .settings: 3
        case .guide: 0
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
