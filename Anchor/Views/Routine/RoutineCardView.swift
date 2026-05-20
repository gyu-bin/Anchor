//
//  RoutineCardView.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct RoutineCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var premium: PremiumStore

    @Bindable var routine: Routine
    var vm: RoutineViewModel
    let allRoutines: [Routine]
    @Binding var editPayload: RoutineItemEditPayload?
    @Binding var paywallReason: PaywallReason?
    @Binding var isExpanded: Bool
    var focusNameOnAppear: Bool = false
    var onFinishEditing: (() -> Void)? = nil

    @State private var editingName: String = ""
    @State private var scheduleDraft = RoutineScheduleDraft()
    @State private var showDeleteConfirm = false
    @FocusState private var nameFieldFocused: Bool

    private var itemCount: Int { routine.items.count }
    private var startTimeText: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "a h:mm"
        return df.string(from: routine.startTime)
    }

    var body: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: 0) {
                header

                if isExpanded {
                    Divider()
                        .padding(.horizontal, AnchorLayout.cardPadding)

                    expandedContent
                        .padding(AnchorLayout.cardPadding)
                        .padding(.top, 8)
                }
            }
        }
        .confirmationDialog(
            AppCopy.Routine.deleteConfirmTitle,
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(AppCopy.Routine.deleteConfirmAction, role: .destructive) {
                vm.deleteRoutine(routine, context: modelContext)
            }
            Button(AppCopy.Common.cancel, role: .cancel) {}
        } message: {
            Text(AppCopy.Routine.deleteConfirmMessage)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                withAnimation(AnchorMotion.spring(response: 0.32, dampingFraction: 0.82)) {
                    if isExpanded {
                        finishEditing()
                    } else {
                        isExpanded = true
                    }
                }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.name)
                            .font(AnchorTypography.cardTitle(scheme))
                            .foregroundStyle(Color.anchorText(scheme))
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)

                        Text(summarySubtitle)
                            .font(.caption)
                            .foregroundStyle(Color.anchorSub(scheme))
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.anchorSub(scheme))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(routine.name)
            .accessibilityHint(isExpanded ? "탭하여 접기" : "탭하여 펼치기")

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.body)
                    .foregroundStyle(Color.anchorSub(scheme))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("루틴 삭제")
        }
        .padding(16)
    }

    private var summarySubtitle: String {
        RoutineSchedule.cardSubtitle(for: routine, itemCount: itemCount, startTimeText: startTimeText)
    }

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoutineEditSection(title: AppCopy.Routine.routineNameLabel, systemImage: "pencil") {
                TextField(AppCopy.Routine.namePlaceholder, text: $editingName)
                    .font(.body)
                    .foregroundStyle(Color.anchorText(scheme))
                    .submitLabel(.done)
                    .focused($nameFieldFocused)
                    .anchorInsetField()
                    .onAppear {
                        editingName = routine.name
                        if focusNameOnAppear {
                            DispatchQueue.main.async {
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

            sectionDivider

            RoutineEditSection(
                title: AppCopy.Routine.scheduleTimeSection,
                systemImage: "calendar"
            ) {
                RoutineScheduleEditor(draft: $scheduleDraft)
                    .onAppear {
                        scheduleDraft = RoutineSchedule.draft(from: routine)
                    }
                    .onChange(of: scheduleDraft) { _, newValue in
                        guard RoutineSchedule.isDraftValid(newValue) else { return }
                        vm.updateSchedule(routine, draft: newValue, context: modelContext)
                        RoutineSync.afterMutation(modelContext: modelContext)
                    }
            }

            sectionDivider

            todosSection

            sectionDivider

            RoutineEditSection(
                title: AppCopy.Routine.blockSection,
                subtitle: AppCopy.Routine.blockSectionHint,
                systemImage: "lock.shield"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    BlockedAppsSection(routine: routine, paywallReason: $paywallReason)
                    Divider()
                        .overlay(Color.anchorBorder(scheme).opacity(0.45))
                    BlockedWebSection(routine: routine, paywallReason: $paywallReason)
                }
            }

            Button {
                finishEditing()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                    Text("완료")
                }
            }
            .buttonStyle(AnchorButtonStyle())
            .padding(.top, 20)
        }
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
            systemImage: "checklist"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if !sorted.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(sorted, id: \.id) { item in
                            todoRow(item)
                        }
                    }
                }

                Button {
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
    }

    private func todoRow(_ item: RoutineItem) -> some View {
        HStack(spacing: 0) {
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
                vm.deleteItem(item, context: modelContext)
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
    }

    private func commitRoutineName() {
        let trimmed = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
        routine.name = trimmed.isEmpty ? "새 루틴" : trimmed
        editingName = routine.name
        try? modelContext.save()
        RoutineSync.afterMutation(modelContext: modelContext)
    }

    private func finishEditing() {
        nameFieldFocused = false
        commitRoutineName()
        onFinishEditing?()
        withAnimation(AnchorMotion.spring(response: 0.32, dampingFraction: 0.82)) {
            isExpanded = false
        }
    }
}
