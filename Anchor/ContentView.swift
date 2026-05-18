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
    @State private var showFocusSplash = true

    var body: some View {
        Group {
            if showFocusSplash {
                PremiumFocusSplash {
                    showFocusSplash = false
                }
            } else if !hasCompletedOnboarding {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            } else {
                mainTabs
            }
        }
        .preferredColorScheme(.light)
        .onReceive(NotificationCenter.default.publisher(for: .anchorOpenTodayTab)) { _ in
            tabRouter.openToday()
        }
        .onReceive(NotificationCenter.default.publisher(for: .anchorRefreshShield)) { _ in
            guard hasCompletedOnboarding, !showFocusSplash else { return }
            Task { await ShieldManager.refresh(modelContext: modelContext) }
        }
        .onChange(of: scenePhase) { _, phase in
            guard hasCompletedOnboarding, !showFocusSplash, phase == .active else { return }
            Task { await ShieldManager.refresh(modelContext: modelContext) }
        }
        .onChange(of: showFocusSplash) { _, showing in
            guard hasCompletedOnboarding, !showing else { return }
            Task { await ShieldManager.refresh(modelContext: modelContext) }
        }
    }

    private var mainTabs: some View {
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
    }
}

#Preview {
    ContentView()
        .environmentObject(TabRouter())
        .modelContainer(PreviewData.container)
}
