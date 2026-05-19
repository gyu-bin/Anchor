//
//  RoutineView.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct RoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var tabRouter: TabRouter
    @Environment(RoutineViewModel.self) private var routineVM
    @EnvironmentObject private var premium: PremiumStore
    @Environment(\.appStoreScreenshotExpandedRoutines) private var screenshotExpandedRoutines

    @Query(sort: [SortDescriptor(\Routine.order)]) private var routines: [Routine]

    @State private var editPayload: RoutineItemEditPayload?
    @State private var expandedRoutineIDs: Set<UUID> = []
    @State private var focusNameRoutineID: UUID?
    @State private var paywallReason: PaywallReason?

    private var orderedRoutines: [Routine] {
        routineVM.sortedRoutines(routines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AnchorLayout.sectionSpacing) {
                    header

                    if orderedRoutines.isEmpty {
                        emptyState
                    } else {
                        ForEach(orderedRoutines, id: \.id) { routine in
                            routineCard(for: routine)
                                .padding(.horizontal, AnchorLayout.screenHorizontal)
                        }
                    }
                }
                .padding(.bottom, 36)
            }
            .anchorScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $editPayload) { payload in
                RoutineItemEditSheet(payload: payload)
                    .presentationDetents([.large])
                    .presentationCornerRadius(28)
            }
            .sheet(item: $paywallReason) { reason in
                PaywallSheet(reason: reason)
            }
            .onAppear {
                if let ids = screenshotExpandedRoutines, !ids.isEmpty, expandedRoutineIDs.isEmpty {
                    expandedRoutineIDs = ids
                }
                fulfillPendingCreateRoutine()
            }
            .onChange(of: tabRouter.selectedTab) { _, tab in
                if tab == 1 {
                    fulfillPendingCreateRoutine()
                }
            }
            .onChange(of: routines.map(\.id)) { _, _ in
                expandedRoutineIDs = expandedRoutineIDs.filter { id in
                    routines.contains { $0.id == id }
                }
                if let focusID = focusNameRoutineID,
                   !routines.contains(where: { $0.id == focusID }) {
                    focusNameRoutineID = nil
                }
                RoutineSync.afterMutation(modelContext: modelContext, refreshShield: false)
            }
        }
    }

    @ViewBuilder
    private func routineCard(for routine: Routine) -> some View {
        RoutineCardView(
            routine: routine,
            vm: routineVM,
            allRoutines: routines,
            editPayload: $editPayload,
            paywallReason: $paywallReason,
            isExpanded: Binding(
                get: { expandedRoutineIDs.contains(routine.id) },
                set: { expanded in
                    if expanded {
                        expandedRoutineIDs.insert(routine.id)
                    } else {
                        expandedRoutineIDs.remove(routine.id)
                    }
                }
            ),
            focusNameOnAppear: focusNameRoutineID == routine.id,
            onFinishEditing: {
                if focusNameRoutineID == routine.id {
                    focusNameRoutineID = nil
                }
            }
        )
        .draggable(routine.id.uuidString) {
            Image(systemName: "line.3.horizontal")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.anchorSub(scheme))
                .padding(8)
                .background(Color.anchorSubBg(scheme))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityLabel("순서 변경")
        }
        .dropDestination(for: String.self) { items, _ in
            guard let dragged = items.first,
                  let draggedID = UUID(uuidString: dragged),
                  draggedID != routine.id,
                  let fromIdx = orderedRoutines.firstIndex(where: { $0.id == draggedID }),
                  let toIdx = orderedRoutines.firstIndex(where: { $0.id == routine.id }) else {
                return false
            }
            withAnimation(AnchorMotion.spring()) {
                routineVM.moveRoutine(
                    from: IndexSet(integer: fromIdx),
                    to: toIdx > fromIdx ? toIdx + 1 : toIdx,
                    routines: routines,
                    context: modelContext
                )
            }
            return true
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            AnchorScreenHeader(
                title: AppCopy.Routine.title,
                subtitle: AppCopy.Routine.subtitle(count: orderedRoutines.count)
            )

            Spacer(minLength: 12)

            Button {
                addNewRoutine()
            } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.anchorAccent(scheme))
                    .clipShape(Circle())
            }
            .accessibilityLabel("새 루틴 추가")
            .padding(.top, 6)
        }
        .padding(.horizontal, AnchorLayout.screenHorizontal)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        AnchorEmptyState(
            icon: "list.bullet.rectangle",
            title: AppCopy.Routine.emptyTitle,
            message: AppCopy.Routine.emptyBody,
            actionTitle: AppCopy.Routine.emptyAction,
            action: addNewRoutine
        )
        .padding(.horizontal, AnchorLayout.screenHorizontal)
    }

    private func fulfillPendingCreateRoutine() {
        guard tabRouter.consumePendingCreateRoutine() else { return }
        Task { @MainActor in
            await Task.yield()
            addNewRoutine()
        }
    }

    private func addNewRoutine() {
        let routine = routineVM.addRoutine(
            name: "새 루틴",
            schedule: RoutineScheduleDraft(),
            context: modelContext,
            routines: routines
        )
        focusNameRoutineID = routine.id
        withAnimation(AnchorMotion.spring(response: 0.32, dampingFraction: 0.82)) {
            expandedRoutineIDs = [routine.id]
        }
    }
}

#Preview {
    RoutineView()
        .environmentObject(TabRouter())
        .environment(RoutineViewModel())
        .environmentObject(PremiumStore())
        .modelContainer(PreviewData.container)
}
