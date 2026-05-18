//
//  RoutineView.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct RoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    @Query(sort: [SortDescriptor(\Routine.order)]) private var routines: [Routine]
    @StateObject private var vm = RoutineViewModel()

    @State private var editPayload: RoutineItemEditPayload?
    @State private var showAddRoutine = false
    @State private var editMode: EditMode = .inactive
    @State private var expandedRoutineIDs: Set<UUID> = []

    private var orderedRoutines: [Routine] {
        vm.sortedRoutines(routines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if orderedRoutines.isEmpty {
                        ContentUnavailableView {
                            Label("루틴이 없어요", systemImage: "anchor")
                        } description: {
                            Text("상단 + 버튼에서 추가하세요")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        Text("내 루틴")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.anchorSub(scheme))
                            .textCase(.uppercase)
                            .kerning(0.5)
                            .padding(.top, 4)

                        ForEach(orderedRoutines, id: \.id) { routine in
                            RoutineCardView(
                                routine: routine,
                                vm: vm,
                                editPayload: $editPayload,
                                isExpanded: Binding(
                                    get: { expandedRoutineIDs.contains(routine.id) },
                                    set: { expanded in
                                        if expanded {
                                            expandedRoutineIDs.insert(routine.id)
                                        } else {
                                            expandedRoutineIDs.remove(routine.id)
                                        }
                                    }
                                )
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .environment(\.editMode, $editMode)
            .background(Color.anchorBg(scheme).ignoresSafeArea())
            .navigationTitle("루틴")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if !orderedRoutines.isEmpty {
                            EditButton()
                        }
                        Button {
                            showAddRoutine = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddRoutine) {
                AddRoutineSheet { name, start in
                    vm.addRoutine(name: name, startTime: start, context: modelContext, routines: routines)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(item: $editPayload) { payload in
                RoutineItemEditSheet(payload: payload)
                    .presentationDetents([.large])
                    .onDisappear {
                        collapseRoutine(payload.routine.id)
                    }
            }
            .onChange(of: routines.map(\.id)) { _, _ in
                expandedRoutineIDs = expandedRoutineIDs.filter { id in
                    routines.contains { $0.id == id }
                }
                Task { await ShieldManager.refresh(modelContext: modelContext) }
            }
        }
    }

    private func collapseRoutine(_ id: UUID) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            expandedRoutineIDs.remove(id)
        }
    }
}

#Preview {
    RoutineView()
        .modelContainer(PreviewData.container)
}
