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
    @Query(sort: [SortDescriptor(\RoutineTemplate.savedAt, order: .reverse)]) private var templates: [RoutineTemplate]

    @State private var editPayload: RoutineItemEditPayload?
    @State private var expandedRoutineIDs: Set<UUID> = []
    @State private var focusNameRoutineID: UUID?
    @State private var paywallReason: PaywallReason?
    @State private var showTemplatePicker = false
    @State private var showAddMenu = false
    @State private var showDeletedToast = false
    @State private var deletedToastTask: Task<Void, Never>?
    @State private var validationToastMessage: String?
    @State private var validationToastTask: Task<Void, Never>?

    private var orderedRoutines: [Routine] {
        routineVM.sortedRoutines(routines)
    }

    private var bottomScrollInset: CGFloat {
        if validationToastMessage != nil || showDeletedToast { return 88 }
        return 36
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: AnchorLayout.sectionSpacing) {
                            header

                            if orderedRoutines.isEmpty {
                                emptyState
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(orderedRoutines, id: \.id) { routine in
                                        routineCard(for: routine, scrollProxy: proxy)
                                            .padding(.horizontal, AnchorLayout.screenHorizontal)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, bottomScrollInset)
                    }
                }

                VStack(spacing: 8) {
                    if let validationToastMessage {
                        AnchorBriefToast(message: validationToastMessage)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    if showDeletedToast {
                        AnchorBriefToast(
                            message: AppCopy.Routine.deletedToast,
                            systemImage: "checkmark.circle.fill",
                            iconColor: { Color.anchorSuccess($0) }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, AnchorLayout.screenHorizontal)
                .padding(.bottom, 12)
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
            .sheet(isPresented: $showTemplatePicker) {
                RoutineTemplatePickerSheet(
                    routines: routines,
                    routineVM: routineVM,
                    onCreated: { routine in
                        focusNameRoutineID = routine.id
                        withAnimation(AnchorMotion.spring(response: 0.32, dampingFraction: 0.82)) {
                            expandedRoutineIDs = [routine.id]
                        }
                    }
                )
            }
            .confirmationDialog(AppCopy.Routine.addRoutinePrompt, isPresented: $showAddMenu, titleVisibility: .visible) {
                Button(AppCopy.Routine.addNewRoutine) {
                    addNewRoutine()
                }
                Button(AppCopy.Routine.loadTemplate) {
                    showTemplatePicker = true
                }
                Button(AppCopy.Common.cancel, role: .cancel) {}
            }
            .onAppear {
                if let ids = screenshotExpandedRoutines, !ids.isEmpty, expandedRoutineIDs.isEmpty {
                    expandedRoutineIDs = ids
                }
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
    private func routineCard(for routine: Routine, scrollProxy: ScrollViewProxy) -> some View {
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
            },
            onDeleted: { presentDeletedToast() },
            onValidationFailed: { result in
                presentValidationToast(result.toastMessage)
                _ = withAnimation(AnchorMotion.spring(response: 0.32, dampingFraction: 0.82)) {
                    expandedRoutineIDs.insert(routine.id)
                }
                if let target = result.scrollTargetID(for: routine.id) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(AnchorMotion.spring(response: 0.35, dampingFraction: 0.85)) {
                            scrollProxy.scrollTo(target, anchor: .center)
                        }
                    }
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
                    showTemplatePicker = true
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.anchorAccent(scheme))
            }
        }
        .padding(.horizontal, AnchorLayout.screenHorizontal)
    }

    private func syncRoutineListState() {
        let ids = Set(routines.map(\.id))
        expandedRoutineIDs = expandedRoutineIDs.filter { ids.contains($0) }
        if let focusID = focusNameRoutineID, !ids.contains(focusID) {
            focusNameRoutineID = nil
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

    private func presentValidationToast(_ message: String) {
        guard !message.isEmpty else { return }
        validationToastTask?.cancel()
        withAnimation(AnchorMotion.spring(response: 0.32)) {
            validationToastMessage = message
        }
        validationToastTask = Task {
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation {
                    validationToastMessage = nil
                }
            }
        }
    }

    private func presentDeletedToast() {
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

    private func addNewRoutine() {
        let routine = routineVM.addRoutine(
            name: "새 루틴",
            schedule: RoutineScheduleDraft(),
            context: modelContext,
            routines: routines
        )
        presentExpandedRoutine(routineID: routine.id, focusName: true)
    }

    /// 상단 + 로 새 루틴 만들 때와 동일 — 카드 펼침 + 이름 포커스
    private func presentExpandedRoutine(routineID: UUID, focusName: Bool) {
        if focusName {
            focusNameRoutineID = routineID
        }
        withAnimation(AnchorMotion.spring(response: 0.32, dampingFraction: 0.82)) {
            expandedRoutineIDs = [routineID]
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
