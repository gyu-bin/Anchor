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

    @Query(sort: [SortDescriptor(\Routine.order)]) private var routines: [Routine]
    @Query(sort: [SortDescriptor(\RoutineTemplate.savedAt, order: .reverse)]) private var templates: [RoutineTemplate]

    @State private var editingRoutine: Routine?
    @State private var focusNameForNewRoutine: UUID?
    @State private var showTemplatePicker = false
    @State private var showAddMenu = false
    @State private var showDeletedToast = false
    @State private var deletedToastTask: Task<Void, Never>?
    @State private var showDuplicatedToast = false
    @State private var duplicatedToastTask: Task<Void, Never>?
    @State private var paywallReason: PaywallReason?

    private var orderedRoutines: [Routine] {
        routineVM.sortedRoutines(routines)
    }

    private var bottomScrollInset: CGFloat {
        (showDeletedToast || showDuplicatedToast) ? 88 : 36
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: AnchorLayout.sectionSpacing) {
                        header

                        if orderedRoutines.isEmpty {
                            emptyState
                        } else {
                            AnchorCard {
                                VStack(spacing: 0) {
                                    ForEach(orderedRoutines, id: \.id) { routine in
                                        routineCard(for: routine)
                                        if routine.id != orderedRoutines.last?.id {
                                            Divider()
                                                .padding(.leading, 16)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, AnchorLayout.screenHorizontal)
                        }
                    }
                    .padding(.bottom, bottomScrollInset)
                }

                if showDeletedToast {
                    AnchorBriefToast(
                        message: AppCopy.Routine.deletedToast,
                        systemImage: "checkmark.circle.fill",
                        iconColor: { Color.anchorSuccess($0) }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, AnchorLayout.screenHorizontal)
                    .padding(.bottom, 12)
                } else if showDuplicatedToast {
                    AnchorBriefToast(
                        message: AppCopy.Routine.duplicatedToast,
                        systemImage: "doc.on.doc.fill",
                        iconColor: { Color.anchorAccent($0) }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, AnchorLayout.screenHorizontal)
                    .padding(.bottom, 12)
                }
            }
            .anchorScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $editingRoutine, onDismiss: { focusNameForNewRoutine = nil }) { routine in
                RoutineEditSheet(
                    routine: routine,
                    allRoutines: routines,
                    focusNameOnAppear: focusNameForNewRoutine == routine.id,
                    onDeleted: { presentDeletedToast() },
                    onFinishEditing: {
                        if focusNameForNewRoutine == routine.id {
                            focusNameForNewRoutine = nil
                        }
                    },
                    onDuplicated: { copy in
                        presentDuplicatedToast()
                        focusNameForNewRoutine = copy.id
                        editingRoutine = copy
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
            .sheet(isPresented: $showTemplatePicker) {
                RoutineTemplatePickerSheet(
                    routines: routines,
                    routineVM: routineVM,
                    onCreated: { routine in
                        focusNameForNewRoutine = routine.id
                        editingRoutine = routine
                    }
                )
            }
            .confirmationDialog(AppCopy.Routine.addRoutinePrompt, isPresented: $showAddMenu, titleVisibility: .visible) {
                Button(AppCopy.Routine.addNewRoutine) {
                    addNewRoutine()
                }
                Button(AppCopy.Routine.loadTemplate) {
                    openTemplatePickerIfAllowed()
                }
                Button(AppCopy.Common.cancel, role: .cancel) {}
            }
            .sheet(item: $paywallReason) { reason in
                PaywallSheet(reason: reason)
            }
            .onAppear {
                RoutineScheduleMaintenance.run(modelContext: modelContext)
                fulfillPendingNavigation()
            }
            .onChange(of: tabRouter.selectedTab) { _, tab in
                if tab == 1 {
                    RoutineScheduleMaintenance.run(modelContext: modelContext)
                    fulfillPendingNavigation()
                }
            }
            .onChange(of: tabRouter.pendingExpandRoutineID) { _, _ in
                guard tabRouter.selectedTab == 1 else { return }
                fulfillPendingNavigation()
            }
            .onChange(of: routines.count) { _, _ in
                syncRoutineListState()
                if tabRouter.selectedTab == 1 {
                    fulfillPendingNavigation()
                }
            }
        }
    }

    @ViewBuilder
    private func routineCard(for routine: Routine) -> some View {
        RoutineCardView(
            routine: routine,
            vm: routineVM,
            allRoutines: routines,
            onTap: { editingRoutine = routine },
            onDeleted: { presentDeletedToast() }
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
            VStack(alignment: .leading, spacing: 4) {
                AnchorScreenHeader(
                    title: AppCopy.Routine.title,
                    subtitle: AppCopy.Routine.subtitle(count: orderedRoutines.count)
                )
                if !premium.isPremium, !canAddMoreRoutines {
                    Text(AppCopy.Premium.routineLimitHint)
                        .font(.caption)
                        .foregroundStyle(Color.anchorSub(scheme))
                }
            }

            Spacer(minLength: 12)

            Button {
                if templates.isEmpty {
                    addNewRoutine()
                } else {
                    showAddMenu = true
                }
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
        VStack(spacing: 12) {
            AnchorEmptyState(
                icon: "list.bullet.rectangle",
                title: AppCopy.Routine.emptyTitle,
                message: AppCopy.Routine.emptyBody,
                actionTitle: AppCopy.Routine.emptyAction,
                action: { templates.isEmpty ? addNewRoutine() : (showAddMenu = true) }
            )
            if !templates.isEmpty {
                Button(AppCopy.Routine.loadTemplate) {
                    openTemplatePickerIfAllowed()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.anchorAccent(scheme))
            }
        }
        .padding(.horizontal, AnchorLayout.screenHorizontal)
    }

    private func syncRoutineListState() {
        if let editingID = editingRoutine?.id, !routines.contains(where: { $0.id == editingID }) {
            editingRoutine = nil
        }
        if let focusID = focusNameForNewRoutine, !routines.contains(where: { $0.id == focusID }) {
            focusNameForNewRoutine = nil
        }
    }

    private func fulfillPendingNavigation() {
        if tabRouter.pendingExpandRoutineID != nil {
            fulfillPendingExpandRoutine()
            return
        }
        fulfillPendingCreateRoutine()
    }

    private func fulfillPendingExpandRoutine() {
        guard let routineID = tabRouter.consumePendingExpandRoutineID() else { return }
        Task { @MainActor in
            await Task.yield()
            if !routines.contains(where: { $0.id == routineID }) {
                try? await Task.sleep(for: .milliseconds(80))
            }
            guard routines.contains(where: { $0.id == routineID }) else { return }
            presentExpandedRoutine(routineID: routineID, focusName: true)
        }
    }

    private func fulfillPendingCreateRoutine() {
        guard tabRouter.consumePendingCreateRoutine() else { return }
        Task { @MainActor in
            await Task.yield()
            addNewRoutine()
        }
    }

    private func presentDeletedToast() {
        duplicatedToastTask?.cancel()
        showDuplicatedToast = false
        deletedToastTask?.cancel()
        withAnimation(AnchorMotion.spring(response: 0.32)) {
            showDeletedToast = true
        }
        deletedToastTask = Task {
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation {
                    showDeletedToast = false
                }
            }
        }
    }

    private func presentDuplicatedToast() {
        deletedToastTask?.cancel()
        showDeletedToast = false
        duplicatedToastTask?.cancel()
        withAnimation(AnchorMotion.spring(response: 0.32)) {
            showDuplicatedToast = true
        }
        duplicatedToastTask = Task {
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation {
                    showDuplicatedToast = false
                }
            }
        }
    }

    private var canAddMoreRoutines: Bool {
        PremiumLimits.canAddRoutine(currentCount: routines.count, isPremium: premium.isPremium)
    }

    private func openTemplatePickerIfAllowed() {
        guard canAddMoreRoutines else {
            paywallReason = .routineLimit
            return
        }
        showTemplatePicker = true
    }

    private func addNewRoutine() {
        guard canAddMoreRoutines else {
            paywallReason = .routineLimit
            return
        }
        let routine = routineVM.addRoutine(
            name: "새 루틴",
            schedule: RoutineScheduleDraft(),
            context: modelContext,
            routines: routines
        )
        focusNameForNewRoutine = routine.id
        editingRoutine = routine
    }

    private func presentExpandedRoutine(routineID: UUID, focusName: Bool) {
        guard let routine = orderedRoutines.first(where: { $0.id == routineID }) else { return }
        if focusName {
            focusNameForNewRoutine = routineID
        }
        editingRoutine = routine
    }
}

#Preview {
    RoutineView()
        .environmentObject(TabRouter())
        .environment(RoutineViewModel())
        .environmentObject(PremiumStore())
        .modelContainer(PreviewData.container)
}
