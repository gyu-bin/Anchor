//
//  TodayView.swift
//  Anchor
//

import SwiftData
import SwiftUI

private struct UndoSnapshot {
    let item: RoutineItem
    let routine: Routine
    let wasCompleted: Bool
}

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    @Query(sort: [SortDescriptor(\Routine.order)]) private var routines: [Routine]
    @State private var vm = TodayViewModel()

    @State private var wasAllComplete = false
    @State private var showCompletionSheet = false
    @State private var scrollTarget: UUID?
    @State private var pendingUndo: UndoSnapshot?
    @State private var showUndoToast = false
    @State private var undoTask: Task<Void, Never>?
    @State private var showErrorToast = false
    @State private var errorToastTask: Task<Void, Never>?
    @State private var isRestToday = RestDayStore.isRestToday()
    @State private var unlockSecondsLeft: Int = 0
    @State private var unlockTimerTask: Task<Void, Never>? = nil
    @State private var tempUnlockUsedToday: Bool = TempUnlockStore.hasBeenUsedToday

    private var sortedRoutines: [Routine] {
        vm.sortedRoutines(routines)
    }

    /// 오늘 일정에 맞는 루틴 (할 일 없는 루틴은 오늘 탭에 표시하지 않음).
    private var scheduledRoutinesToday: [Routine] {
        vm.routinesForToday(sortedRoutines)
    }

    private var actionableRoutinesToday: [Routine] {
        vm.actionableRoutinesForToday(sortedRoutines)
    }

    private var todayLogs: [DailyLog] {
        actionableRoutinesToday.compactMap { routine in
            try? vm.todayLog(for: routine, context: modelContext)
        }
    }

    private var dateTitle: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.setLocalizedDateFormatFromTemplate("EEEE, MMMd")
        return df.string(from: Date())
    }

    private var greeting: String {
        if isRestToday { return AppCopy.Today.restDayActive }
        return AppCopy.Today.greeting(hour: Calendar.current.component(.hour, from: Date()))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: AnchorLayout.sectionSpacing) {
                            AnchorScreenHeader(title: greeting, subtitle: dateTitle)

                            if routines.isEmpty, TodayEmptyHintStore.shouldShow {
                                emptyState
                            } else if scheduledRoutinesToday.isEmpty, TodayEmptyHintStore.shouldShow {
                                noScheduleTodayState
                            } else if isRestToday {
                                restDayCard
                            } else {
                                if !actionableRoutinesToday.isEmpty {
                                    OverallProgressCard(
                                        routines: actionableRoutinesToday,
                                        logs: todayLogs,
                                        blockSummary: ShieldManager.aggregatedBlockedSummary(
                                            routines: actionableRoutinesToday,
                                            modelContext: modelContext
                                        )
                                    )
                                }

                                ForEach(actionableRoutinesToday, id: \.id) { routine in
                                    if let log = try? vm.todayLog(for: routine, context: modelContext) {
                                        RoutineSectionCard(
                                            routine: routine,
                                            log: log,
                                            blockSummary: ShieldManager.displaySummary(
                                                for: routine,
                                                modelContext: modelContext
                                            ),
                                            isActivelyLocking: ShieldManager.isActivelyLocking(
                                                routine: routine,
                                                modelContext: modelContext
                                            ),
                                            unlockSecondsLeft: unlockSecondsLeft,
                                            tempUnlockUsedToday: tempUnlockUsedToday,
                                            canExtendDeadline: RoutineDeadline.canExtendDeadlineToday(
                                                for: routine,
                                                isComplete: log.isFullyCompleted
                                            ),
                                            onUnlock: { handleTempUnlock() },
                                            onRelockNow: { handleRelockNow() },
                                            onExtendDeadline: { handleExtendDeadline(for: routine) },
                                            onToggle: { item in
                                                toggle(item: item, routine: routine)
                                            }
                                        )
                                        .id(routine.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AnchorLayout.screenHorizontal)
                        .padding(.bottom, bottomScrollInset)
                    }
                    .onChange(of: scrollTarget) { _, target in
                        guard let target else { return }
                        withAnimation(AnchorMotion.spring(response: 0.35, dampingFraction: 0.7)) {
                            proxy.scrollTo(target, anchor: .center)
                        }
                    }
                }

                VStack(spacing: 8) {
                    if showErrorToast {
                        AnchorBriefToast(message: AppCopy.Today.toggleFailed)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    if showUndoToast {
                        UndoToast { performUndo() }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, AnchorLayout.screenHorizontal)
                .padding(.bottom, 12)
            }
            .anchorScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                isRestToday = RestDayStore.isRestToday()
                refreshCompletionBannerState()
                syncAfterTodayChange()
                let remaining = TempUnlockStore.remainingSeconds
                if remaining > 0 {
                    unlockSecondsLeft = remaining
                    startUnlockCountdown()
                } else if TempUnlockStore.expiresAt != nil {
                    TempUnlockStore.deactivate()
                    Task { await ShieldManager.refresh(modelContext: modelContext) }
                }
            }
            .onDisappear {
                unlockTimerTask?.cancel()
                unlockTimerTask = nil
            }
            .onChange(of: routines.map(\.id)) { _, _ in
                applyRoutineListChange()
            }
            .onChange(of: routines.map(\.items.count)) { _, _ in
                applyRoutineListChange()
            }
            .onChange(of: actionableRoutinesToday.map(\.id)) { _, ids in
                if !ids.isEmpty { TodayEmptyHintStore.markSeen() }
            }
            .sheet(isPresented: $showCompletionSheet) {
                completionSheet
                    .presentationDetents([.height(300)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            }
        }
    }

    private var restDayCard: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(AppCopy.Today.restDayBody)
                    .font(.subheadline)
                    .lineSpacing(4)
                    .foregroundStyle(Color.anchorSub(scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(AppCopy.Today.restDayCancel) {
                    clearRestToday()
                }
                .buttonStyle(AnchorTextButtonStyle())
            }
            .padding(AnchorLayout.cardPadding)
        }
    }

    private func clearRestToday() {
        withAnimation(AnchorMotion.spring(response: 0.35, dampingFraction: 0.8)) {
            RestDayStore.clearRestToday()
            isRestToday = false
        }
        syncAfterTodayChange()
    }

    private var noScheduleTodayState: some View {
        AnchorEmptyState(
            icon: "calendar",
            title: AppCopy.Today.noScheduleTitle,
            message: AppCopy.Today.noScheduleBody
        )
        .onAppear { TodayEmptyHintStore.markSeen() }
    }

    private var bottomScrollInset: CGFloat {
        if showUndoToast { return 88 }
        if showErrorToast { return 72 }
        return 36
    }

    /// 루틴이 없을 때 처음 한 번만 안내(버튼 없음 — 추가는 루틴 탭에서).
    private var emptyState: some View {
        AnchorEmptyState(
            icon: "sun.max",
            title: AppCopy.Today.emptyTitle,
            message: AppCopy.Today.emptyBody
        )
        .onAppear { TodayEmptyHintStore.markSeen() }
    }

    private func toggle(item: RoutineItem, routine: Routine) {
        guard !isRestToday else { return }
        withAnimation(AnchorMotion.spring(response: 0.35, dampingFraction: 0.7)) {
            do {
                let log = try vm.todayLog(for: routine, context: modelContext)
                let wasCompleted = log.completedItems.contains(item.id)

                try vm.toggleCompletion(item: item, routine: routine, context: modelContext)
                try modelContext.save()

                if let updatedLog = try? vm.todayLog(for: routine, context: modelContext),
                   updatedLog.isFullyCompleted {
                    NotificationManager.cancelReminders(for: routine)
                    AppReviewManager.recordRoutineFullyCompleted()
                    DeadlineGraceStore.resetMissCount()
                }

                presentUndo(item: item, routine: routine, wasCompleted: wasCompleted)

                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.success)

                if let log = try? vm.todayLog(for: routine, context: modelContext),
                   let next = vm.firstIncompleteItem(routine: routine, log: log) {
                    scrollTarget = next.id
                }

                let allDone = (try? vm.allRoutinesFullyCompletedToday(
                    routines: sortedRoutines,
                    context: modelContext
                )) ?? false
                if allDone && !wasAllComplete {
                    showCompletionSheet = true
                }
                wasAllComplete = allDone

                syncAfterTodayChange()
            } catch {
                presentToggleError()
            }
        }
    }

    private func presentToggleError() {
        errorToastTask?.cancel()
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.error)
        withAnimation(AnchorMotion.spring(response: 0.32)) {
            showErrorToast = true
        }
        errorToastTask = Task {
            try? await Task.sleep(for: .seconds(2.8))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation {
                    showErrorToast = false
                }
            }
        }
    }

    private func presentUndo(item: RoutineItem, routine: Routine, wasCompleted: Bool) {
        undoTask?.cancel()
        pendingUndo = UndoSnapshot(item: item, routine: routine, wasCompleted: wasCompleted)
        withAnimation(AnchorMotion.spring(response: 0.32)) {
            showUndoToast = true
        }
        undoTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation {
                    showUndoToast = false
                    pendingUndo = nil
                }
            }
        }
    }

    private func performUndo() {
        guard let undo = pendingUndo else { return }
        undoTask?.cancel()
        do {
            try vm.setCompletion(
                item: undo.item,
                routine: undo.routine,
                completed: undo.wasCompleted,
                context: modelContext
            )
            try modelContext.save()
            wasAllComplete = (try? vm.allRoutinesFullyCompletedToday(routines: routines, context: modelContext)) ?? false
            syncAfterTodayChange()
        } catch {
            presentToggleError()
        }
        withAnimation {
            showUndoToast = false
            pendingUndo = nil
        }
    }

    private func refreshCompletionBannerState() {
        let allDone = (try? vm.allRoutinesFullyCompletedToday(routines: routines, context: modelContext)) ?? false
        wasAllComplete = allDone
    }

    private func applyRoutineListChange() {
        vm.reconcileTodayState(routines: sortedRoutines, context: modelContext)
        try? modelContext.save()

        let allDone = (try? vm.allRoutinesFullyCompletedToday(routines: routines, context: modelContext)) ?? false
        if allDone && !wasAllComplete {
            showCompletionSheet = true
        }
        wasAllComplete = allDone
        syncAfterTodayChange()
    }

    private func handleExtendDeadline(for routine: Routine) {
        guard RoutineDeadlineExtensionStore.applyExtension(routineID: routine.id) else { return }
        NotificationManager.refreshTodayDeadlineReminderAfterExtension(for: routine)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Task { await ShieldManager.refresh(modelContext: modelContext) }
    }

    private func handleTempUnlock() {
        TempUnlockStore.activate(minutes: 10)
        tempUnlockUsedToday = true
        unlockSecondsLeft = TempUnlockStore.remainingSeconds
        if let expiresAt = TempUnlockStore.expiresAt {
            TempUnlockActivityManager.start(expiresAt: expiresAt)
        }
        Task { await ShieldManager.refresh(modelContext: modelContext) }
        startUnlockCountdown()
    }

    private func handleRelockNow() {
        unlockTimerTask?.cancel()
        unlockTimerTask = nil
        TempUnlockStore.deactivate()
        unlockSecondsLeft = 0
        TempUnlockActivityManager.end()
        Task { await ShieldManager.refresh(modelContext: modelContext) }
    }

    private func startUnlockCountdown() {
        unlockTimerTask?.cancel()
        unlockTimerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                let remaining = TempUnlockStore.remainingSeconds
                unlockSecondsLeft = remaining
                if remaining == 0 {
                    TempUnlockStore.deactivate()
                    TempUnlockActivityManager.end()
                    await ShieldManager.refresh(modelContext: modelContext)
                    break
                }
            }
        }
    }

    private func syncAfterTodayChange() {
        try? modelContext.save()
        RoutineSync.afterMutation(modelContext: modelContext, refreshShield: true)
        WidgetDataStore.reloadWidgetsImmediately()
        let fullDays = HistoryAnalytics.weekFullDaysCount(
            logs: (try? modelContext.fetch(FetchDescriptor<DailyLog>())) ?? [],
            routines: routines.filter { !$0.items.isEmpty },
            now: Date(),
            cal: .current
        )
        NotificationManager.updateWeeklySummaryContent(fullDays: fullDays)
    }

    private var completionSheet: some View {
        VStack(spacing: 24) {
            CompletionBanner(
                totalItems: routines.reduce(0) { $0 + $1.items.count }
            )

            Button(AppCopy.Today.completeConfirm) {
                showCompletionSheet = false
                Task { await ShieldManager.refresh(modelContext: modelContext) }
            }
            .buttonStyle(AnchorButtonStyle())
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .presentationBackground(Color.anchorBg(scheme))
    }
}
