//
//  RoutineTemplatePickerSheet.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct RoutineTemplatePickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var premium: PremiumStore

    @Query(sort: [SortDescriptor(\RoutineTemplate.savedAt, order: .reverse)]) private var templates: [RoutineTemplate]

    let routines: [Routine]
    let routineVM: RoutineViewModel
    var onCreated: (Routine) -> Void

    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    ContentUnavailableView(
                        AppCopy.Routine.templateEmptyTitle,
                        systemImage: "clock.arrow.circlepath",
                        description: Text(AppCopy.Routine.templateEmptyBody)
                    )
                } else {
                    List {
                        ForEach(templates, id: \.id) { template in
                            Button {
                                create(from: template)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(Color.anchorText(scheme))
                                    Text(RoutineTemplateStore.subtitle(for: template))
                                        .font(.caption)
                                        .foregroundStyle(Color.anchorSub(scheme))
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteTemplates)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(AppCopy.Routine.templatePickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppCopy.Common.cancel) { dismiss() }
                }
            }
            .sheet(item: $paywallReason) { reason in
                PaywallSheet(reason: reason)
            }
        }
    }

    private func create(from template: RoutineTemplate) {
        guard PremiumLimits.canAddRoutine(
            currentCount: routines.count,
            isPremium: premium.isPremium
        ) else {
            paywallReason = .routineLimit
            return
        }
        let routine = routineVM.createRoutine(
            from: template,
            context: modelContext,
            routines: routines
        )
        onCreated(routine)
        dismiss()
    }

    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(templates[index])
        }
        try? modelContext.save()
    }
}
