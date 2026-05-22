//
//  RoutineCardView.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct RoutineCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    @Bindable var routine: Routine
    var vm: RoutineViewModel
    let allRoutines: [Routine]
    var onTap: (() -> Void)? = nil
    var onDeleted: (() -> Void)? = nil

    @State private var showDeleteConfirm = false

    private var itemCount: Int { routine.items.count }

    private var startTimeText: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "a h:mm"
        return df.string(from: routine.startTime)
    }

    private var summarySubtitle: String {
        RoutineSchedule.cardSubtitle(for: routine, itemCount: itemCount, startTimeText: startTimeText)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Button {
                onTap?()
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(routine.name)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.anchorText(scheme))
                            .lineLimit(1)
                        Text(summarySubtitle)
                            .font(.caption)
                            .foregroundStyle(Color.anchorSub(scheme))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.anchorSub(scheme).opacity(0.45))
                }
                .padding(.leading, 16)
                .padding(.trailing, 8)
                .padding(.vertical, 13)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(routine.name)
            .accessibilityHint("탭하여 편집")

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundStyle(Color.anchorDanger(scheme).opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("루틴 삭제")
        }
        .id(routine.id)
        .confirmationDialog(
            AppCopy.Routine.deleteConfirmTitle,
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(AppCopy.Routine.deleteConfirmAction, role: .destructive) {
                let id = routine.id
                if let target = allRoutines.first(where: { $0.id == id }) {
                    vm.deleteRoutine(target, context: modelContext)
                    onDeleted?()
                }
            }
            Button(AppCopy.Common.cancel, role: .cancel) {}
        } message: {
            Text(AppCopy.Routine.deleteConfirmMessage)
        }
    }
}
