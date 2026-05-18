//
//  ContentView.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var tabRouter: TabRouter

    @AppStorage(AppGuideStorage.hasSeenGuideKey) private var hasSeenAppGuide = false
    @AppStorage("appearanceMode") private var appearanceModeRaw = AppearanceMode.system.rawValue
    @State private var showFocusSplash = true
    @State private var showGuide = false

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some View {
        Group {
            if showFocusSplash {
                PremiumFocusSplash {
                    showFocusSplash = false
                    if !hasSeenAppGuide {
                        showGuide = true
                    }
                }
            } else if showGuide {
                AppGuideView {
                    showGuide = false
                    bootstrapAfterGuide()
                }
            } else {
                mainTabs
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
        .onReceive(NotificationCenter.default.publisher(for: .anchorOpenTodayTab)) { _ in
            tabRouter.openToday()
        }
        .onReceive(NotificationCenter.default.publisher(for: .anchorOpenHistoryTab)) { _ in
            tabRouter.openHistory()
        }
        .onReceive(NotificationCenter.default.publisher(for: .anchorRefreshShield)) { _ in
            guard hasSeenAppGuide, !showFocusSplash, !showGuide else { return }
            Task { await ShieldManager.refresh(modelContext: modelContext) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .anchorCompleteNextItem)) { _ in
            completeNextFromIntent()
        }
        .onChange(of: scenePhase) { _, phase in
            guard hasSeenAppGuide, !showFocusSplash, !showGuide, phase == .active else { return }
            consumeIntentFlags()
            Task { await ShieldManager.refresh(modelContext: modelContext) }
        }
        .onAppear {
            migrateLegacyOnboardingFlag()
            RoutineSchedule.repairLegacyRoutines(in: modelContext)
            guard hasSeenAppGuide, !showFocusSplash, !showGuide else { return }
            consumeIntentFlags()
        }
    }

    private var mainTabs: some View {
        TabView(selection: $tabRouter.selectedTab) {
            TodayView()
                .tabItem { Label("오늘", systemImage: "sun.max.fill") }
                .tag(0)

            RoutineView()
                .tabItem { Label("루틴", systemImage: "list.bullet.rectangle.fill") }
                .tag(1)

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
    }

    /// 예전 온보딩을 마친 사용자는 가이드를 본 것으로 처리
    private func migrateLegacyOnboardingFlag() {
        if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"), !hasSeenAppGuide {
            hasSeenAppGuide = true
        }
    }

    private func bootstrapAfterGuide() {
        Task { @MainActor in
            _ = await NotificationManager.requestAuthorization()
            try? NotificationManager.rescheduleAll(modelContext: modelContext)
            await ShieldManager.refresh(modelContext: modelContext)
            let routines = (try? modelContext.fetch(FetchDescriptor<Routine>())) ?? []
            WidgetSync.refresh(modelContext: modelContext, routines: routines)
        }
    }

    @MainActor
    private func consumeIntentFlags() {
        if IntentRouter.consumeOpenToday() {
            tabRouter.openToday()
        }
        if IntentRouter.consumeCompleteNext() {
            completeNextFromIntent()
        }
    }

    private func completeNextFromIntent() {
        tabRouter.openToday()
        let vm = TodayViewModel()
        let routines = (try? modelContext.fetch(FetchDescriptor<Routine>())) ?? []
        _ = try? vm.completeNextItem(routines: routines, context: modelContext)
        try? modelContext.save()
        Task {
            await ShieldManager.refresh(modelContext: modelContext)
            WidgetSync.refresh(modelContext: modelContext, routines: routines)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TabRouter())
        .environmentObject(PremiumStore())
        .modelContainer(PreviewData.container)
}
