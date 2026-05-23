//
//  RoutineEditSheet.swift
//  Anchor
//

import FamilyControls
import SwiftData
import SwiftUI

struct RoutineEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(RoutineViewModel.self) private var routineVM
    @EnvironmentObject private var premium: PremiumStore

    @Bindable var routine: Routine
    let allRoutines: [Routine]
    var focusNameOnAppear: Bool = false
    var onDeleted: (() -> Void)? = nil
    var onFinishEditing: (() -> Void)? = nil
    var onDuplicated: ((Routine) -> Void)? = nil

    @State private var editPayload: RoutineItemEditPayload?
    @State private var paywallReason: PaywallReason?
    @State private var editingName: String = ""
    @State private var scheduleDraft = RoutineScheduleDraft()
    @State private var scheduleDraftReady = false
    @State private var showValidationErrors = false
    @State private var showDeleteConfirm = false
    @State private var validationToastMessage: String?
    @State private var validationToastTask: Task<Void, Never>?
    @FocusState private var nameFieldFocused: Bool

    private var itemCount: Int { routine.items.count }
    private var hasTodos: Bool { itemCount > 0 }
    private var hasBlockedApps: Bool {
        RoutineSetupValidation.hasBlockedApps(routine)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            routineNameField

                            sectionDivider

                            setupChecklist

                            sectionDivider

                            todosSection
                                .id("routine-todos-\(routine.id)")

                            sectionDivider

                            appsBlockSection
                                .id("routine-apps-\(routine.id)")

                            sectionDivider

                            RoutineEditSection(
                                title: AppCopy.Routine.scheduleTimeSection,
                                systemImage: "calendar"
                            ) {
                                RoutineScheduleEditor(draft: $scheduleDraft)
                                    .onAppear {
                                        scheduleDraft = RoutineSchedule.draft(from: routine)
                                        scheduleDraftReady = false
                                        DispatchQueue.main.async {
                                            scheduleDraftReady = true
                                        }
                                    }
                                    .onDisappear {
                                        scheduleDraftReady = false
                                    }
                                    .onChange(of: scheduleDraft) { _, newValue in
                                        guard scheduleDraftReady else { return }
                                        guard RoutineSchedule.isDraftValid(newValue) else { return }
                                        let current = RoutineSchedule.draft(from: routine)
                                        guard newValue != current else { return }
                                        routineVM.updateSchedule(routine, draft: newValue, context: modelContext)
                                    }
                            }

                            Button {
                                saveRoutine()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text(AppCopy.Routine.saveRoutine)
                                }
                            }
                            .buttonStyle(AnchorButtonStyle())
                            .padding(.top, 20)
                        }
                        .padding(AnchorLayout.cardPadding)
                        .padding(.bottom, 36)
                        .onChange(of: routine.items.count) { _, _ in clearValidationIfReady() }
                        .onChange(of: routine.shieldSelectionData) { _, _ in clearValidationIfReady() }
                        .onChange(of: showValidationErrors) { _, isShowing in
                            guard isShowing else { return }
                            let validation = RoutineSetupValidation.validate(routine)
                            guard let target = validation.scrollTargetID(for: routine.id) else { return }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(AnchorMotion.spring(response: 0.35, dampingFraction: 0.85)) {
                                    proxy.scrollTo(target, anchor: .center)
                                }
                            }
                        }
                    }
                }

                if let msg = validationToastMessage {
                    AnchorBriefToast(message: msg)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, AnchorLayout.screenHorizontal)
                        .padding(.bottom, 20)
                }
            }
            .anchorScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(editingName.isEmpty ? routine.name : editingName)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        nameFieldFocused = false
                        commitRoutineName()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            duplicateRoutine()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(Color.anchorAccent(scheme))
                        }
                        .accessibilityLabel(AppCopy.Routine.duplicate)

                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.anchorDanger(scheme))
                        }
                        .accessibilityLabel(AppCopy.Routine.deleteConfirmAction)
                    }
                }
            }
        }
        .sheet(item: $editPayload) { payload in
            RoutineItemEditSheet(payload: payload)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .sheet(item: $paywallReason) { reason in
            PaywallSheet(reason: reason)
        }
        .confirmationDialog(
            AppCopy.Routine.deleteConfirmTitle,
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(AppCopy.Routine.deleteConfirmAction, role: .destructive) {
                let id = routine.id
                if let target = allRoutines.first(where: { $0.id == id }) {
                    routineVM.deleteRoutine(target, context: modelContext)
                    dismiss()
                    onDeleted?()
                }
            }
            Button(AppCopy.Common.cancel, role: .cancel) {}
        } message: {
            Text(AppCopy.Routine.deleteConfirmMessage)
        }
    }

    // MARK: - Subviews

    private var routineNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppCopy.Routine.routineNameLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.anchorText(scheme))

            TextField(AppCopy.Routine.namePlaceholder, text: $editingName)
                .font(.body)
                .foregroundStyle(Color.anchorText(scheme))
                .submitLabel(.done)
                .focused($nameFieldFocused)
                .anchorInsetField()
                .onAppear {
                    editingName = routine.name
                    if focusNameOnAppear {
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(420))
                            guard !Task.isCancelled else { return }
                            nameFieldFocused = true
                        }
                    }
                }
                .onSubmit {
                    nameFieldFocused = false
                    commitRoutineName()
                }
                .onChange(of: nameFieldFocused) { _, focused in
                    if !focused { commitRoutineName() }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var setupChecklist: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppCopy.Routine.setupRequiredHint)
                .font(.caption)
                .foregroundStyle(Color.anchorSub(scheme))

            HStack(spacing: 10) {
                checklistChip(
                    title: AppCopy.Routine.checklistTodos,
                    isDone: hasTodos,
                    isHighlighted: showValidationErrors && !hasTodos
                )
                checklistChip(
                    title: AppCopy.Routine.checklistApps,
                    isDone: hasBlockedApps,
                    isHighlighted: showValidationErrors && !hasBlockedApps
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func checklistChip(title: String, isDone: Bool, isHighlighted: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(
                    isDone
                        ? Color.anchorSuccess(scheme)
                        : (isHighlighted ? Color.anchorDanger(scheme) : Color.anchorSub(scheme))
                )
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    isHighlighted ? Color.anchorDanger(scheme) : Color.anchorText(scheme)
                )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            isHighlighted
                ? Color.anchorDanger(scheme).opacity(0.1)
                : Color.anchorSubBg(scheme)
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    isHighlighted ? Color.anchorDanger(scheme).opacity(0.5) : Color.clear,
                    lineWidth: 1
                )
        )
    }

    private var sectionDivider: some View {
        Divider()
            .overlay(Color.anchorBorder(scheme).opacity(0.4))
            .padding(.vertical, 14)
    }

    @ViewBuilder
    private var todosSection: some View {
        let sorted = routine.items.sorted { $0.order < $1.order }

        RoutineEditSection(
            title: AppCopy.Routine.todosSection,
            subtitle: todosSectionSubtitle(sorted: sorted),
            systemImage: "checklist"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if sorted.isEmpty {
                    Text(AppCopy.Routine.todosEmptyHint)
                        .font(.subheadline)
                        .foregroundStyle(
                            showValidationErrors
                                ? Color.anchorDanger(scheme)
                                : Color.anchorSub(scheme)
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 8) {
                        ForEach(sorted, id: \.id) { item in
                            todoRow(item, sorted: sorted)
                        }
                    }
                }

                Button {
                    guard PremiumLimits.canAddItem(
                        currentCount: routine.items.count,
                        isPremium: premium.isPremium
                    ) else {
                        paywallReason = .itemLimit
                        return
                    }
                    showValidationErrors = false
                    editPayload = RoutineItemEditPayload(routine: routine, item: nil)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.body)
                        Text(AppCopy.Routine.addTodo)
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                }
                .buttonStyle(AnchorTextButtonStyle())
            }
        }
        .overlay(validationBorder(isHighlighted: showValidationErrors && !hasTodos))
    }

    private func todoRow(_ item: RoutineItem, sorted: [RoutineItem]) -> some View {
        HStack(spacing: 0) {
            Image(systemName: "line.3.horizontal")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.anchorSub(scheme).opacity(0.45))
                .padding(.leading, 12)
                .accessibilityLabel(AppCopy.Routine.reorderItems)

            Button {
                editPayload = RoutineItemEditPayload(routine: routine, item: item)
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.anchorHighlight(scheme))
                            .frame(width: 40, height: 40)
                        Image(systemName: item.icon)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.anchorAccent(scheme))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.anchorText(scheme))
                            .multilineTextAlignment(.leading)
                        if item.duration > 0 {
                            Text(AppCopy.Routine.durationMinutes(item.duration))
                                .font(.caption)
                                .foregroundStyle(Color.anchorSub(scheme))
                        }
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.anchorSub(scheme).opacity(0.6))
                }
                .padding(.leading, 12)
                .padding(.trailing, 4)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(item.name) 편집")

            Button(role: .destructive) {
                routineVM.deleteItem(item, context: modelContext)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.anchorSub(scheme).opacity(0.45))
                    .padding(.horizontal, 12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(item.name) 삭제")
        }
        .background(Color.anchorSubBg(scheme))
        .clipShape(RoundedRectangle(cornerRadius: AnchorLayout.rowRadius, style: .continuous))
        .draggable(item.id.uuidString) {
            Image(systemName: "line.3.horizontal")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.anchorSub(scheme))
                .padding(8)
                .background(Color.anchorSubBg(scheme))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .dropDestination(for: String.self) { items, _ in
            guard let dragged = items.first,
                  let draggedID = UUID(uuidString: dragged),
                  draggedID != item.id,
                  let fromIdx = sorted.firstIndex(where: { $0.id == draggedID }),
                  let toIdx = sorted.firstIndex(where: { $0.id == item.id }) else {
                return false
            }
            withAnimation(AnchorMotion.spring()) {
                routineVM.moveItem(
                    from: IndexSet(integer: fromIdx),
                    to: toIdx > fromIdx ? toIdx + 1 : toIdx,
                    in: routine,
                    context: modelContext
                )
            }
            return true
        }
    }

    private func todosSectionSubtitle(sorted: [RoutineItem]) -> String? {
        if !premium.isPremium,
           !PremiumLimits.canAddItem(currentCount: routine.items.count, isPremium: false) {
            return AppCopy.Premium.itemLimitHint
        }
        if !sorted.isEmpty {
            return AppCopy.Routine.reorderItemsHint
        }
        return nil
    }

    private func duplicateRoutine() {
        guard PremiumLimits.canAddRoutine(
            currentCount: allRoutines.count,
            isPremium: premium.isPremium
        ) else {
            paywallReason = .routineLimit
            return
        }
        let copy = routineVM.duplicateRoutine(routine, context: modelContext, routines: allRoutines)
        dismiss()
        onDuplicated?(copy)
    }

    private var appsBlockSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoutineEditSection(
                title: AppCopy.Routine.blockAppsSection,
                subtitle: AppCopy.Routine.blockAppsSectionHint,
                systemImage: "lock.shield"
            ) {
                BlockedAppsSection(routine: routine, paywallReason: $paywallReason)
            }

            if showValidationErrors && !hasBlockedApps {
                BlockedInlineError(message: AppCopy.Routine.validationNeedApps)
                    .padding(.top, 8)
            }

            DisclosureGroup {
                BlockedWebSection(routine: routine, paywallReason: $paywallReason)
                    .padding(.top, 8)
            } label: {
                Text(AppCopy.Routine.blockWebOptional)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.anchorSub(scheme))
            }
            .padding(.top, 12)
        }
        .overlay(validationBorder(isHighlighted: showValidationErrors && !hasBlockedApps))
    }

    private func validationBorder(isHighlighted: Bool) -> some View {
        RoundedRectangle(cornerRadius: AnchorLayout.rowRadius, style: .continuous)
            .strokeBorder(
                isHighlighted ? Color.anchorDanger(scheme) : Color.clear,
                lineWidth: isHighlighted ? 1.5 : 0
            )
    }

    // MARK: - Logic

    private func clearValidationIfReady() {
        guard showValidationErrors, RoutineSetupValidation.validate(routine).isValid else { return }
        showValidationErrors = false
    }

    private func commitRoutineName() {
        let trimmed = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
        routine.name = trimmed.isEmpty ? "새 루틴" : trimmed
        editingName = routine.name
        try? modelContext.save()
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

    private func saveRoutine() {
        nameFieldFocused = false
        commitRoutineName()

        let validation = RoutineSetupValidation.validate(routine)
        guard validation.isValid else {
            showValidationErrors = true
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            presentValidationToast(validation.toastMessage)
            return
        }

        showValidationErrors = false
        RoutineSync.afterMutation(modelContext: modelContext, refreshShield: false)
        onFinishEditing?()
        dismiss()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
