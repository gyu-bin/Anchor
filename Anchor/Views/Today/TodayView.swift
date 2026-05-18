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

    private var sortedRoutines: [Routine] {
        vm.sortedRoutines(routines)
    }

    private var routinesWithItems: [Routine] {
        vm.routinesForToday(sortedRoutines)
    }

    private var todayLogs: [DailyLog] {
        routinesWithItems.compactMap { routine in
            try? vm.todayLog(for: routine, context: modelContext)
        }
    }

    private var isRestToday: Bool {
        RestDayStore.isRestToday()
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

                            if !routinesWithItems.isEmpty {
                                restDayControl
                            }

                            if routinesWithItems.isEmpty {
                                emptyState
                            } else if isRestToday {
                                restDayCard
                            } else {
                                OverallProgressCard(
                                    routines: routinesWithItems,
                                    logs: todayLogs,
                                    blockSummary: ShieldManager.aggregatedDisplaySummary(
                                        routines: routinesWithItems,
                                        modelContext: modelContext
                                    ),
                                    isActivelyLocking: ShieldManager.isAnyActivelyLocking(
                                        routines: routinesWithItems,
                                        modelContext: modelContext
                                    )
                                )

                                ForEach(routinesWithItems, id: \.id) { routine in
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
                        .padding(.bottom, showUndoToast ? 88 : 36)
                    }
                    .onChange(of: scrollTarget) { _, target in
                        guard let target else { return }
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            proxy.scrollTo(target, anchor: .center)
                        }
                    }
                }

                if showUndoToast {
                    UndoToast { performUndo() }
                        .padding(.horizontal, AnchorLayout.screenHorizontal)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .anchorScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                refreshCompletionBannerState()
                syncWidgetAndNotifications()
                Task { await ShieldManager.refresh(modelContext: modelContext) }
            }
            .onChange(of: routines.map(\.id)) { _, _ in
                refreshCompletionBannerState()
                syncWidgetAndNotifications()
                Task { await ShieldManager.refresh(modelContext: modelContext) }
            }
            .onChange(of: routines.map(\.blockedWebs)) { _, _ in
                Task { await ShieldManager.refresh(modelContext: modelContext) }
            }
            .sheet(isPresented: $showCompletionSheet) {
                completionSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            }
        }
    }

    private var restDayControl: some View {
        Button {
            if isRestToday {
                RestDayStore.clearRestToday()
            } else {
                RestDayStore.setRestToday()
            }
            syncWidgetAndNotifications()
            Task { await ShieldManager.refresh(modelContext: modelContext) }
        } label: {
            Text(isRestToday ? AppCopy.Today.restDayCancel : AppCopy.Today.restDayButton)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isRestToday ? Color.anchorSub(scheme) : Color.anchorAccent(scheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isRestToday ? Color.anchorSubBg(scheme) : Color.anchorHighlight(scheme))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var restDayCard: some View {
        AnchorCard {
            Text(AppCopy.Today.restDayBody)
                .font(.subheadline)
                .lineSpacing(4)
                .foregroundStyle(Color.anchorSub(scheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AnchorLayout.cardPadding)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(AppCopy.Today.emptyTitle)
                    .font(.title3.bold())
                    .foregroundStyle(Color.anchorText(scheme))
                Text(AppCopy.Today.emptyBody)
                    .font(.subheadline)
                    .foregroundStyle(Color.anchorSub(scheme))
                    .multilineTextAlignment(.center)
            }

            Button(AppCopy.Today.emptyAction) {
                tabRouter.selectedTab = 1
            }
            .buttonStyle(AnchorButtonStyle())
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func toggle(item: RoutineItem, routine: Routine) {
        guard !isRestToday else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            do {
                let log = try vm.todayLog(for: routine, context: modelContext)
                let wasCompleted = log.completedItems.contains(item.id)

                try vm.toggleCompletion(item: item, routine: routine, context: modelContext)
                try modelContext.save()

                presentUndo(item: item, routine: routine, wasCompleted: wasCompleted)

                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.success)

                if let log = try? vm.todayLog(for: routine, context: modelContext),
                   let next = vm.firstIncompleteItem(routine: routine, log: log) {
                    scrollTarget = next.id
                }

                let allDone = (try? vm.allRoutinesFullyCompletedToday(routines: routines, context: modelContext)) ?? false
                if allDone && !wasAllComplete {
                    showCompletionSheet = true
                }
                wasAllComplete = allDone

                syncWidgetAndNotifications()
                Task { await ShieldManager.refresh(modelContext: modelContext) }
            } catch {
                // no-op
            }
        }
    }

    private func presentUndo(item: RoutineItem, routine: Routine, wasCompleted: Bool) {
        undoTask?.cancel()
        pendingUndo = UndoSnapshot(item: item, routine: routine, wasCompleted: wasCompleted)
        withAnimation(.spring(response: 0.32)) {
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
            syncWidgetAndNotifications()
            Task { await ShieldManager.refresh(modelContext: modelContext) }
        } catch {
            // no-op
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

    private func syncWidgetAndNotifications() {
        WidgetSync.refresh(modelContext: modelContext, routines: routines)
        let fullDays = HistoryView.weekFullDaysCount(
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
