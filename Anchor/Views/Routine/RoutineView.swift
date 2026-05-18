//
//  RoutineView.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct RoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var premium: PremiumStore

    @Query(sort: [SortDescriptor(\Routine.order)]) private var routines: [Routine]
    @StateObject private var vm = RoutineViewModel()

    @State private var editPayload: RoutineItemEditPayload?
    @State private var expandedRoutineIDs: Set<UUID> = []
    @State private var focusNameRoutineID: UUID?
    @State private var paywallReason: PaywallReason?

    private var orderedRoutines: [Routine] {
        vm.sortedRoutines(routines)
    }

    var body: some View {
        NavigationStack {
            Group {
                if orderedRoutines.isEmpty {
                    ScrollView {
                        header
                        emptyState
                    }
                } else {
                    List {
                        Section {
                            header
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }

                        Section {
                            ForEach(orderedRoutines, id: \.id) { routine in
                                RoutineCardView(
                                    routine: routine,
                                    vm: vm,
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
                                    focusNameOnAppear: focusNameRoutineID == routine.id
                                )
                                .listRowInsets(EdgeInsets(
                                    top: 6,
                                    leading: AnchorLayout.screenHorizontal,
                                    bottom: 6,
                                    trailing: AnchorLayout.screenHorizontal
                                ))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .contentMargins(.bottom, 36, for: .scrollContent)
                }
            }
            .anchorScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $editPayload) { payload in
                RoutineItemEditSheet(payload: payload)
                    .presentationDetents([.large])
                    .presentationCornerRadius(28)
                    .onDisappear {
                        collapseRoutine(payload.routine.id)
                    }
            }
            .sheet(item: $paywallReason) { reason in
                PaywallSheet(reason: reason)
            }
            .onChange(of: routines.map(\.id)) { _, _ in
                expandedRoutineIDs = expandedRoutineIDs.filter { id in
                    routines.contains { $0.id == id }
                }
                if let focusID = focusNameRoutineID,
                   !routines.contains(where: { $0.id == focusID }) {
                    focusNameRoutineID = nil
                }
                Task { await ShieldManager.refresh(modelContext: modelContext) }
            }
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
            .padding(.top, 6)
        }
        .padding(.horizontal, AnchorLayout.screenHorizontal)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(AppCopy.Routine.emptyTitle)
                    .font(.title3.bold())
                    .foregroundStyle(Color.anchorText(scheme))
                Text(AppCopy.Routine.emptyBody)
                    .font(.subheadline)
                    .foregroundStyle(Color.anchorSub(scheme))
                    .multilineTextAlignment(.center)
            }

            Button(AppCopy.Routine.emptyAction) {
                addNewRoutine()
            }
            .buttonStyle(AnchorButtonStyle())
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, AnchorLayout.screenHorizontal)
    }

    private func addNewRoutine() {
        guard PremiumLimits.canAddRoutine(currentCount: routines.count, isPremium: premium.isPremium) else {
            paywallReason = .routineLimit
            return
        }
        let routine = vm.addRoutine(
            name: "새 루틴",
            schedule: RoutineScheduleDraft(),
            context: modelContext,
            routines: routines
        )
        focusNameRoutineID = routine.id
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            expandedRoutineIDs = [routine.id]
        }
    }

    private func collapseRoutine(_ id: UUID) {
        _ = withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            expandedRoutineIDs.remove(id)
        }
    }
}

#Preview {
    RoutineView()
        .environmentObject(PremiumStore())
        .modelContainer(PreviewData.container)
}
