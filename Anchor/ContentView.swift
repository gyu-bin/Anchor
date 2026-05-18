//
//  ContentView.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var tabRouter: TabRouter

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                TabView(selection: $tabRouter.selectedTab) {
                    TodayView()
                        .tabItem { Label("오늘", systemImage: "sun.max") }
                        .tag(0)

                    RoutineView()
                        .tabItem { Label("루틴", systemImage: "list.bullet") }
                        .tag(1)

                    HistoryView()
                        .tabItem { Label("기록", systemImage: "chart.bar") }
                        .tag(2)
                }
                .tint(Color.anchorAccent(scheme))
                .toolbarBackground(Color("AnchorCard"), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .anchorOpenTodayTab)) { _ in
            tabRouter.openToday()
        }
        .onReceive(NotificationCenter.default.publisher(for: .anchorRefreshShield)) { _ in
            guard hasCompletedOnboarding else { return }
            Task { await ShieldManager.refresh(modelContext: modelContext) }
        }
        .onChange(of: scenePhase) { _, phase in
            guard hasCompletedOnboarding, phase == .active else { return }
            Task { await ShieldManager.refresh(modelContext: modelContext) }
        }
        .task(id: hasCompletedOnboarding) {
            guard hasCompletedOnboarding else { return }
            await ShieldManager.refresh(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TabRouter())
        .modelContainer(PreviewData.container)
}
