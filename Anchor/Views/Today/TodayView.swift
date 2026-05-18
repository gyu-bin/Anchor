//
//  TodayView.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var tabRouter: TabRouter

    @Query(sort: [SortDescriptor(\Routine.order)]) private var routines: [Routine]
    @State private var vm = TodayViewModel()

    @State private var wasAllComplete = false
    @State private var showCompletionSheet = false
    @State private var scrollTarget: UUID?

    private var sortedRoutines: [Routine] {
        vm.sortedRoutines(routines)
    }

    private var routinesWithItems: [Routine] {
        sortedRoutines.filter { !$0.items.isEmpty }
    }

    private var todayLogs: [DailyLog] {
        routinesWithItems.compactMap { routine in
            try? vm.todayLog(for: routine, context: modelContext)
        }
    }

    private var dateTitle: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.setLocalizedDateFormatFromTemplate("EEEE MMMd")
        return df.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header

                        if routinesWithItems.isEmpty {
                            emptyState
                        } else {
                            OverallProgressCard(
                                routines: sortedRoutines,
                                logs: todayLogs,
                                blockSummary: ShieldManager.aggregatedDisplaySummary(
                                    routines: sortedRoutines,
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .onChange(of: scrollTarget) { _, target in
                    guard let target else { return }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        proxy.scrollTo(target, anchor: .center)
                    }
                }
            }
            .background(Color.anchorBg(scheme).ignoresSafeArea())
            .navigationTitle("오늘")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                refreshCompletionBannerState()
                Task { await ShieldManager.refresh(modelContext: modelContext) }
            }
            .onChange(of: routines.map(\.id)) { _, _ in
                refreshCompletionBannerState()
                Task { await ShieldManager.refresh(modelContext: modelContext) }
            }
            .onChange(of: routines.map(\.blockedWebs)) { _, _ in
                Task { await ShieldManager.refresh(modelContext: modelContext) }
            }
            .sheet(isPresented: $showCompletionSheet) {
                completionSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var header: some View {
        Text(dateTitle)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.anchorSub(scheme))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("루틴이 없어요", systemImage: "anchor")
        } description: {
            Text("루틴 탭에서 첫 루틴을 만들어보세요")
        } actions: {
            Button("루틴 만들기") {
                tabRouter.selectedTab = 1
            }
            .buttonStyle(AnchorButtonStyle())
            .padding(.horizontal, 8)
        }
    }

    private func toggle(item: RoutineItem, routine: Routine) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            do {
                try vm.toggleCompletion(item: item, routine: routine, context: modelContext)
                try modelContext.save()

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

                Task { await ShieldManager.refresh(modelContext: modelContext) }
            } catch {
                // no-op
            }
        }
    }

    private func refreshCompletionBannerState() {
        let allDone = (try? vm.allRoutinesFullyCompletedToday(routines: routines, context: modelContext)) ?? false
        wasAllComplete = allDone
    }

    private var completionSheet: some View {
        VStack(spacing: 20) {
            CompletionBanner(
                totalItems: routines.reduce(0) { $0 + $1.items.count }
            )

            Button("확인") {
                showCompletionSheet = false
                Task { await ShieldManager.refresh(modelContext: modelContext) }
            }
            .buttonStyle(AnchorButtonStyle())
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .presentationBackground(Color.anchorBg(scheme))
    }
}

#Preview {
    TodayView()
        .environmentObject(TabRouter())
        .modelContainer(PreviewData.container)
}

enum PreviewData {
    static var container: ModelContainer {
        let schema = Schema([Routine.self, RoutineItem.self, DailyLog.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let routine = Routine(name: "아침 루틴", startTime: Date(), order: 0)
        let i1 = RoutineItem(name: "독서", duration: 20, icon: "book", order: 0, routine: routine)
        let i2 = RoutineItem(name: "명상", duration: 10, icon: "brain.head.profile", order: 1, routine: routine)
        routine.items = [i1, i2]
        routine.blockedWebs = ["youtube.com"]
        container.mainContext.insert(routine)
        container.mainContext.insert(i1)
        container.mainContext.insert(i2)
        return container
    }
}
