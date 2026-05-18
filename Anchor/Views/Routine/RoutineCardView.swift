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
    @ObservedObject var vm: RoutineViewModel
    @Binding var editPayload: RoutineItemEditPayload?
    @Binding var paywallReason: PaywallReason?
    @Binding var isExpanded: Bool
    var focusNameOnAppear: Bool = false
    var onFinishEditing: (() -> Void)? = nil

    @State private var editingName: String = ""
    @State private var scheduleDraft = RoutineScheduleDraft()
    @State private var weekdayAlert = false
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
                        .padding(.top, 4)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                guard !isExpanded else { return }
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    isExpanded = true
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

            if isExpanded {
                Button {
                    finishEditing()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.anchorAccent(scheme))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("편집 완료")
            }

            Button(role: .destructive) {
                vm.deleteRoutine(routine, context: modelContext)
            } label: {
                Image(systemName: "trash")
                    .font(.body)
            }
            .buttonStyle(.borderless)
        }
        .padding(16)
    }

    private var summarySubtitle: String {
        RoutineSchedule.cardSubtitle(for: routine, itemCount: itemCount, startTimeText: startTimeText)
    }

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("루틴 이름")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.anchorSub(scheme))
                TextField("루틴 이름", text: $editingName)
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

            RoutineScheduleEditor(draft: $scheduleDraft)
                .onAppear {
                    scheduleDraft = RoutineSchedule.draft(from: routine)
                }
                .onChange(of: scheduleDraft) { _, newValue in
                    guard newValue.kind != .weekdays || !newValue.activeWeekdays.isEmpty else {
                        weekdayAlert = true
                        scheduleDraft = RoutineSchedule.draft(from: routine)
                        return
                    }
                    vm.updateSchedule(routine, draft: newValue, context: modelContext)
                    Task { await ShieldManager.refresh(modelContext: modelContext) }
                }

            VStack(alignment: .leading, spacing: 8) {
                Text("항목")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.anchorSub(scheme))

                let sorted = routine.items.sorted { $0.order < $1.order }
                if sorted.isEmpty {
                    Text(AppCopy.Routine.noItems)
                        .font(.subheadline)
                        .foregroundStyle(Color.anchorSub(scheme))
                } else {
                    VStack(spacing: 0) {
                        ForEach(sorted, id: \.id) { item in
                            Button {
                                editPayload = RoutineItemEditPayload(routine: routine, item: item)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: item.icon)
                                        .foregroundStyle(Color.anchorAccent(scheme))
                                        .frame(width: 28)
                                    Text(item.name)
                                        .foregroundStyle(Color.anchorText(scheme))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.anchorSub(scheme))
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 4)
                            }
                            .buttonStyle(.plain)

                            if item.id != sorted.last?.id {
                                Divider()
                            }
                        }
                    }
                    .background(Color.anchorSubBg(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: AnchorLayout.rowRadius, style: .continuous))
                }

                Button {
                    guard PremiumLimits.canAddItem(
                        currentCount: routine.items.count,
                        isPremium: premium.isPremium
                    ) else {
                        paywallReason = .itemLimit
                        return
                    }
                    editPayload = RoutineItemEditPayload(routine: routine, item: nil)
                } label: {
                    Label(AppCopy.Routine.addItem, systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .tint(Color.anchorAccent(scheme))
            }

            BlockedAppsSection(routine: routine, paywallReason: $paywallReason)
            BlockedWebSection(routine: routine, paywallReason: $paywallReason)
        }
        .alert(AppCopy.Routine.weekdayRequired, isPresented: $weekdayAlert) {
            Button("확인", role: .cancel) {}
        }
    }

    private func commitRoutineName() {
        let trimmed = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
        routine.name = trimmed.isEmpty ? "새 루틴" : trimmed
        editingName = routine.name
        try? modelContext.save()
        try? NotificationManager.rescheduleAll(modelContext: modelContext)
    }

    private func finishEditing() {
        nameFieldFocused = false
        commitRoutineName()
        onFinishEditing?()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            isExpanded = false
        }
    }
}
