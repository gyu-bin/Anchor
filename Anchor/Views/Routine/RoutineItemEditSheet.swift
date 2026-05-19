//
//  RoutineItemEditSheet.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct RoutineItemEditPayload: Identifiable {
    let id = UUID()
    let routine: Routine
    let item: RoutineItem?
}

struct RoutineItemEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    let payload: RoutineItemEditPayload
    @Environment(RoutineViewModel.self) private var routineVM

    @State private var name: String
    @State private var icon: String
    @State private var durationMinutes: Int

    init(payload: RoutineItemEditPayload) {
        self.payload = payload
        _name = State(initialValue: payload.item?.name ?? "")
        _icon = State(initialValue: payload.item?.icon ?? "book")
        _durationMinutes = State(initialValue: payload.item?.duration ?? 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("이름") {
                    TextField(AppCopy.Routine.todoNamePlaceholder, text: $name)
                }

                Section("예상 시간") {
                    Picker("예상 시간", selection: $durationMinutes) {
                        Text("없음").tag(0)
                        Text("5분").tag(5)
                        Text("10분").tag(10)
                        Text("15분").tag(15)
                        Text("20분").tag(20)
                        Text("30분").tag(30)
                        Text("45분").tag(45)
                        Text("60분").tag(60)
                    }
                    .pickerStyle(.menu)
                }

                Section("아이콘") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 10)], spacing: 10) {
                        ForEach(RoutineViewModel.iconChoices, id: \.self) { sym in
                            Button {
                                icon = sym
                            } label: {
                                Image(systemName: sym)
                                    .font(.title3)
                                    .frame(width: 48, height: 48)
                                    .background(sym == icon ? Color.anchorAccent(scheme).opacity(0.18) : Color.anchorSubBg(scheme))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(sym == icon ? Color.anchorAccent(scheme) : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.anchorText(scheme))
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.anchorBg(scheme))
            .navigationTitle(payload.item == nil ? AppCopy.Routine.addTodoSheetTitle : AppCopy.Routine.editTodoSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("저장")
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let item = payload.item {
            routineVM.updateItem(
                item,
                name: trimmed,
                icon: icon,
                duration: durationMinutes,
                context: modelContext
            )
        } else {
            routineVM.addItem(
                to: payload.routine,
                name: trimmed,
                icon: icon,
                duration: durationMinutes,
                context: modelContext
            )
        }
        dismiss()
    }
}
