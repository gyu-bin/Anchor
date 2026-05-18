//
//  RoutineCardView.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct RoutineCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @Environment(\.editMode) private var editMode

    @Bindable var routine: Routine
    @ObservedObject var vm: RoutineViewModel
    @Binding var editPayload: RoutineItemEditPayload?
    @Binding var isExpanded: Bool

    @State private var editingName: String = ""
    @FocusState private var nameFieldFocused: Bool

    private var itemCount: Int { routine.items.count }
    private var startTimeText: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "a h:mm"
        return df.string(from: routine.startTime)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if isExpanded {
                Divider()
                    .padding(.horizontal, 16)

                expandedContent
                    .padding(16)
                    .padding(.top, 4)
            }
        }
        .background(Color("AnchorCard"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.name)
                            .font(.headline)
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
        if itemCount == 0 {
            return startTimeText
        }
        return "\(itemCount)개 항목 · \(startTimeText)"
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
                    .padding(12)
                    .background(Color.anchorSubBg(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .onAppear { editingName = routine.name }
                    .onSubmit {
                        commitRoutineName()
                        collapseCard()
                    }
                    .onChange(of: nameFieldFocused) { _, focused in
                        if !focused { commitRoutineName() }
                    }
                    .onChange(of: editingName) { _, newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        routine.name = trimmed
                        try? modelContext.save()
                        try? NotificationManager.rescheduleAll(modelContext: modelContext)
                    }
            }

            DatePicker(
                "시작 시간",
                selection: $routine.startTime,
                displayedComponents: .hourAndMinute
            )
            .environment(\.locale, Locale(identifier: "ko_KR"))
            .onChange(of: routine.startTime) { _, _ in
                try? modelContext.save()
                try? NotificationManager.rescheduleAll(modelContext: modelContext)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("항목")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.anchorSub(scheme))

                let sorted = routine.items.sorted { $0.order < $1.order }
                if sorted.isEmpty {
                    Text("항목이 없습니다")
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
                        .onMove { from, to in
                            vm.moveItem(from: from, to: to, in: routine, context: modelContext)
                        }
                        .onDelete { offsets in
                            vm.deleteItems(at: offsets, in: routine, context: modelContext)
                        }
                    }
                    .background(Color.anchorSubBg(scheme).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button {
                    editPayload = RoutineItemEditPayload(routine: routine, item: nil)
                } label: {
                    Label("항목 추가", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .tint(Color.anchorAccent(scheme))
            }

            BlockedAppsSection(routine: routine)
            BlockedWebSection(routine: routine)
        }
    }

    private func commitRoutineName() {
        let trimmed = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
        routine.name = trimmed.isEmpty ? "새 루틴" : trimmed
        editingName = routine.name
        try? modelContext.save()
        try? NotificationManager.rescheduleAll(modelContext: modelContext)
    }

    private func collapseCard() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            isExpanded = false
        }
    }
}
