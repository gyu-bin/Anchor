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
    @EnvironmentObject private var tabRouter: TabRouter

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
    @State private var infoToastMessage: String?
    @State private var infoToastTask: Task<Void, Never>?
    @State private var todayUIRevision = 0
    @State private var scheduleClockTimer: Timer?
    @State private var lastScheduleUISignature = ""
    @State private var showQuickLock = false
    @State private var isRestToday = RestDayStore.isRestToday()
    @State private var unlockSecondsLeft: Int = 0
    @State private var unlockTimerTask: Task<Void, Never>? = nil
    @State private var quickLockSecondsLeft: Int = 0
    @State private var quickLockTimerTask: Task<Void, Never>? = nil
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

    private var todayLogSnapshots: [TodayLogSnapshot] {
        modelContext.processPendingChanges()
        return actionableRoutinesToday.compactMap {
            TodayLogSnapshot.capture(for: $0, context: modelContext)
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
                            todayHeader

                            if quickLockSecondsLeft > 0 {
                                QuickLockStatusCard(
                                    remainingSeconds: quickLockSecondsLeft,
                                    blockSummary: ShieldManager.quickLockDisplaySummary(),
                                    onManage: { showQuickLock = true }
                                )
                            }

                            if !isRestToday, !routines.isEmpty {
                                restDayActivateRow
                            }

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
                                        logSnapshots: todayLogSnapshots,
                                        lockSnapshot: TodayProgressSnapshot.make(
                                            routines: actionableRoutinesToday,
                                            logSnapshots: todayLogSnapshots,
                                            modelContext: modelContext
                                        ),
                                        blockSummary: ShieldManager.aggregatedBlockedSummary(
                                            routines: actionableRoutinesToday,
                                            modelContext: modelContext
                                        )
                                    )
                                }

                                ForEach(actionableRoutinesToday, id: \.id) { routine in
                                    if let logSnapshot = TodayLogSnapshot.capture(for: routine, context: modelContext) {
                                        RoutineSectionCard(
                                            routine: routine,
                                            logSnapshot: logSnapshot,
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
                                                isComplete: logSnapshot.isFullyCompleted
                                            ),
                                            onUnlock: { handleTempUnlock() },
                                            onRelockNow: { handleRelockNow() },
                                            onExtendDeadline: { handleExtendDeadline(for: routine) },
                                            onToggle: { item in
                                                toggle(item: item, routine: routine)
                                            }
                                        )
                                        .id("\(routine.id)-\(todayUIRevision)")
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
                    if let infoToastMessage {
                        AnchorBriefToast(message: infoToastMessage)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
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
                refreshTodayScheduleUI()
                startScheduleClockIfNeeded()
                if TempUnlockStore.isActive, let expiresAt = TempUnlockStore.expiresAt {
                    TempUnlockActivityManager.reconcile(expiresAt: expiresAt)
                }
                let remaining = TempUnlockStore.remainingSeconds
                if remaining > 0 {
                    unlockSecondsLeft = remaining
                    startUnlockCountdown()
                } else if TempUnlockStore.expiresAt != nil {
                    TempUnlockStore.deactivate()
                    Task { await ShieldManager.refresh(modelContext: modelContext) }
                }
                refreshQuickLockState(reconcileLiveActivity: true)
            }
            .onDisappear {
                unlockTimerTask?.cancel()
                unlockTimerTask = nil
                quickLockTimerTask?.cancel()
                quickLockTimerTask = nil
                scheduleClockTimer?.invalidate()
                scheduleClockTimer = nil
            }
            .onReceive(NotificationCenter.default.publisher(for: .anchorTodayScheduleRefresh)) { _ in
                refreshTodayScheduleUI()
            }
            .onReceive(NotificationCenter.default.publisher(for: .anchorRefreshShield)) { _ in
                refreshTodayScheduleUI()
            }
            .onChange(of: routines.map(\.id)) { oldIds, newIds in
                guard tabRouter.selectedTab == 0 else { return }
                if newIds.count != oldIds.count {
                    Task { @MainActor in
                        modelContext.processPendingChanges()
                        await Task.yield()
                        let added = newIds.count > oldIds.count
                        applyRoutineListChange(syncWidgets: !added)
                        startScheduleClockIfNeeded()
                    }
                } else {
                    applyRoutineListChange()
                    startScheduleClockIfNeeded()
                }
            }
            .onChange(of: routines.map(\.items.count)) { _, _ in
                guard tabRouter.selectedTab == 0 else { return }
                Task { @MainActor in
                    await Task.yield()
                    applyRoutineListChange(syncWidgets: false)
                }
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
            .sheet(isPresented: $showQuickLock, onDismiss: syncAfterQuickLockDismiss) {
                NavigationStack {
                    QuickLockView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(AppCopy.QuickLock.close) {
                                    showQuickLock = false
                                }
                            }
                        }
                }
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
        }
    }

    private var todayHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            AnchorScreenHeader(title: greeting, subtitle: dateTitle)
            Button {
                showQuickLock = true
            } label: {
                VStack(spacing: 4) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.anchorAccent(scheme))
                            .frame(width: 44, height: 44)
                            .background(Color.anchorAccent(scheme).opacity(0.12))
                            .clipShape(Circle())
                        if QuickLockStore.isActive {
                            Circle()
                                .fill(Color.anchorWarning(scheme))
                                .frame(width: 10, height: 10)
                                .offset(x: 2, y: -2)
                        }
                    }
                    Text(AppCopy.Today.quickLockCaption)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.anchorSub(scheme))
                }
                .frame(width: 52)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppCopy.Today.quickLockButton)
        }
    }

    private func syncAfterQuickLockDismiss() {
        refreshQuickLockState(reconcileLiveActivity: true)
        Task { await ShieldManager.refresh(modelContext: modelContext) }
    }

    private func refreshQuickLockState(reconcileLiveActivity: Bool = false) {
        let remaining = QuickLockStore.remainingSeconds
        if remaining > 0 {
            quickLockSecondsLeft = remaining
            startQuickLockCountdown()
            if reconcileLiveActivity, let expiresAt = QuickLockStore.expiresAt {
                let count = ShieldManager.quickLockDisplaySummary().appTokens.count
                QuickLockActivityManager.start(expiresAt: expiresAt, appCount: count)
            }
        } else {
            quickLockTimerTask?.cancel()
            quickLockTimerTask = nil
            quickLockSecondsLeft = 0
            if QuickLockStore.expiresAt != nil {
                QuickLockStore.deactivate()
                QuickLockActivityManager.end()
            }
        }
        todayUIRevision += 1
    }

    private func startQuickLockCountdown() {
        quickLockTimerTask?.cancel()
        quickLockTimerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                let remaining = QuickLockStore.remainingSeconds
                quickLockSecondsLeft = remaining
                if remaining == 0 {
                    QuickLockStore.deactivate()
                    QuickLockActivityManager.end()
                    await ShieldManager.refresh(modelContext: modelContext)
                    break
                }
            }
        }
    }

    private func refreshTodayScheduleUI() {
        let signature = ShieldScheduleWatcher.scheduleUISignature(modelContext: modelContext)
        guard signature != lastScheduleUISignature else { return }
        lastScheduleUISignature = signature
        todayUIRevision += 1
    }

    /// 시작·마감 시각이 다가온 루틴이 있으면 1초마다 UI 상태를 맞춥니다.
    private func startScheduleClockIfNeeded() {
        scheduleClockTimer?.invalidate()
        scheduleClockTimer = nil

        let hasUpcomingBoundary = actionableRoutinesToday.contains { routine in
            let now = Date()
            if !ShieldManager.hasRoutineStartedToday(routine, now: now) { return true }
            if let end = RoutineDeadline.endTimeToday(for: routine, now: now), now < end { return true }
            return false
        }
        guard hasUpcomingBoundary else { return }

        scheduleClockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                refreshTodayScheduleUI()
                let stillNeeded = actionableRoutinesToday.contains { routine in
                    let now = Date()
                    if !ShieldManager.hasRoutineStartedToday(routine, now: now) { return true }
                    if let end = RoutineDeadline.endTimeToday(for: routine, now: now), now < end { return true }
                    return false
                }
                if !stillNeeded {
                    scheduleClockTimer?.invalidate()
                    scheduleClockTimer = nil
                }
            }
        }
    }

    private var restDayActivateRow: some View {
        Button {
            activateRestToday()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "moon.zzz.fill")
                    .font(.subheadline.weight(.semibold))
                Text(AppCopy.Today.restDayButton)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .opacity(0.5)
            }
            .foregroundStyle(Color.anchorSub(scheme))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.anchorSubBg(scheme))
            .clipShape(RoundedRectangle(cornerRadius: AnchorLayout.rowRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AppCopy.Today.restDayButton)
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

    private func activateRestToday() {
        withAnimation(AnchorMotion.spring(response: 0.35, dampingFraction: 0.8)) {
            RestDayStore.setRestToday()
            isRestToday = true
        }
        syncAfterTodayChange()
        Task { await ShieldManager.refresh(modelContext: modelContext) }
    }

    private func clearRestToday() {
        withAnimation(AnchorMotion.spring(response: 0.35, dampingFraction: 0.8)) {
            RestDayStore.clearRestToday()
            isRestToday = false
        }
        syncAfterTodayChange()
        Task { await ShieldManager.refresh(modelContext: modelContext) }
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
        if showErrorToast || infoToastMessage != nil { return 72 }
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

                if !wasCompleted && RoutineDeadline.isTodayDeadlinePassed(for: routine) {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    presentInfoToast(AppCopy.Today.cannotCheckAfterDeadline)
                    return
                }

                if wasCompleted, !vm.canUncheckItem(item, routine: routine, logId: log.id, context: modelContext) {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    presentInfoToast(AppCopy.Today.cannotUncheckAfterDeadline)
                    return
                }

                let completedBefore = log.completedItems
                try vm.toggleCompletion(item: item, routine: routine, context: modelContext)
                guard log.completedItems != completedBefore else { return }
                try modelContext.save()

                if let updatedLog = try? vm.todayLog(for: routine, context: modelContext),
                   updatedLog.isFullyCompleted {
                    NotificationManager.cancelReminders(for: routine)
                    AppReviewManager.recordRoutineFullyCompleted()
                }

                if !wasCompleted || vm.canUncheckItem(item, routine: routine, logId: log.id, context: modelContext) {
                    presentUndo(item: item, routine: routine, wasCompleted: wasCompleted)
                }

                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.success)

                if let snap = TodayLogSnapshot.capture(for: routine, context: modelContext),
                   let next = vm.firstIncompleteItem(routine: routine, snapshot: snap) {
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

    private func presentInfoToast(_ message: String) {
        infoToastTask?.cancel()
        withAnimation(AnchorMotion.spring(response: 0.32)) {
            infoToastMessage = message
        }
        infoToastTask = Task {
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation {
                    infoToastMessage = nil
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
            let log = try vm.todayLog(for: undo.routine, context: modelContext)
            if !undo.wasCompleted, !vm.canUncheckItem(undo.item, routine: undo.routine, logId: log.id, context: modelContext) {
                withAnimation {
                    showUndoToast = false
                    pendingUndo = nil
                }
                return
            }
            let completedBefore = log.completedItems
            try vm.setCompletion(
                item: undo.item,
                routine: undo.routine,
                completed: undo.wasCompleted,
                context: modelContext
            )
            guard log.completedItems != completedBefore else {
                withAnimation {
                    showUndoToast = false
                    pendingUndo = nil
                }
                return
            }
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

    private func applyRoutineListChange(syncWidgets: Bool = true) {
        modelContext.processPendingChanges()
        vm.reconcileTodayState(routines: sortedRoutines, context: modelContext)
        try? modelContext.save()

        let allDone = (try? vm.allRoutinesFullyCompletedToday(routines: routines, context: modelContext)) ?? false
        if allDone && !wasAllComplete {
            showCompletionSheet = true
        }
        wasAllComplete = allDone
        if syncWidgets {
            syncAfterTodayChange()
        }
    }

    private func handleExtendDeadline(for routine: Routine) {
        guard RoutineDeadlineExtensionStore.applyExtension(routineID: routine.id) else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            presentInfoToast(AppCopy.Routine.extendFailed)
            return
        }
        todayUIRevision += 1
        refreshTodayScheduleUI()
        NotificationManager.refreshTodayDeadlineReminderAfterExtension(for: routine)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        presentInfoToast(AppCopy.Routine.extendSuccess)
        Task { await ShieldManager.refresh(modelContext: modelContext) }
    }

    private func handleTempUnlock() {
        TempUnlockStore.activate(minutes: 10)
        tempUnlockUsedToday = true
        unlockSecondsLeft = TempUnlockStore.remainingSeconds
        if let expiresAt = TempUnlockStore.expiresAt {
            TempUnlockActivityManager.start(expiresAt: expiresAt)
            if !TempUnlockActivityManager.areActivitiesEnabled {
                presentInfoToast(AppCopy.Today.liveActivityDisabled)
            }
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
        let liveIds = Set(routines.map(\.id))
        let logs = DailyLogFetcher.fetchedLogs(liveRoutineIds: liveIds, context: modelContext)
        let fullDays = HistoryAnalytics.weekFullDaysCount(
            logs: logs,
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
