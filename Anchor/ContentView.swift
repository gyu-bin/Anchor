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
    @State private var routineViewModel = RoutineViewModel()

    @AppStorage(AppGuideStorage.hasSeenGuideKey) private var hasSeenAppGuide = false
    @AppStorage("appearanceMode") private var appearanceModeRaw = AppearanceMode.defaultMode.rawValue
    @State private var showGuide = false

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some View {
        Group {
            if showGuide {
                AppGuideView {
                    showGuide = false
                    bootstrapAfterGuide()
                }
            } else {
                mainTabs
            }
        }
        .environment(routineViewModel)
        .preferredColorScheme(appearanceMode.colorScheme)
        .onReceive(NotificationCenter.default.publisher(for: .anchorOpenTodayTab)) { _ in
            tabRouter.openToday()
        }
        .onReceive(NotificationCenter.default.publisher(for: .anchorOpenHistoryTab)) { _ in
            tabRouter.openHistory()
        }
        .onReceive(NotificationCenter.default.publisher(for: .anchorRefreshShield)) { _ in
            guard hasSeenAppGuide, !showGuide else { return }
            Task { await ShieldManager.refresh(modelContext: modelContext) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .anchorCompleteNextItem)) { _ in
            completeNextFromIntent()
        }
        .onChange(of: scenePhase) { _, phase in
            guard hasSeenAppGuide, !showGuide else { return }
            switch phase {
            case .active:
                RoutineScheduleMaintenance.run(modelContext: modelContext)
                ShieldScheduleWatcher.startPolling(modelContext: modelContext)
                consumeIntentFlags()
                Task { await ShieldManager.refresh(modelContext: modelContext) }
            case .background, .inactive:
                ShieldScheduleWatcher.stopPolling()
            @unknown default:
                break
            }
        }
        .onAppear {
            AppModelContextHolder.main = modelContext
            migrateLegacyOnboardingFlag()
            RoutineSchedule.repairLegacyRoutines(in: modelContext)
            RoutineScheduleMaintenance.run(modelContext: modelContext)
            if !hasSeenAppGuide {
                showGuide = true
            } else {
                ShieldScheduleWatcher.startPolling(modelContext: modelContext)
                consumeIntentFlags()
            }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $tabRouter.selectedTab) {
            TodayView()
                .tabItem { Label("오늘", systemImage: "sun.max.fill") }
                .tag(0)
                .accessibilityLabel("오늘")

            RoutineView()
                .tabItem { Label("루틴", systemImage: "list.bullet.rectangle.fill") }
                .tag(1)
                .accessibilityLabel("루틴")

            HistoryView()
                .tabItem { Label("기록", systemImage: "chart.bar.fill") }
                .tag(2)
                .accessibilityLabel("기록")

            SettingsView()
                .tabItem { Label("설정", systemImage: "gearshape.fill") }
                .tag(3)
                .accessibilityLabel("설정")
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
            await AppPermissions.requestEssentialPermissions()
            RoutineSync.afterMutation(modelContext: modelContext)
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
        RoutineSync.afterMutation(modelContext: modelContext)
    }
}

#Preview {
    ContentView()
        .environmentObject(TabRouter())
        .environment(RoutineViewModel())
        .environmentObject(PremiumStore())
        .modelContainer(PreviewData.container)
}
