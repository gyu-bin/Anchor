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
    @StateObject private var vm = RoutineViewModel()

    @State private var name: String
    @State private var icon: String

    init(payload: RoutineItemEditPayload) {
        self.payload = payload
        _name = State(initialValue: payload.item?.name ?? "")
        _icon = State(initialValue: payload.item?.icon ?? "book")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("이름") {
                    TextField("루틴 항목 이름", text: $name)
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
            .navigationTitle(payload.item == nil ? "항목 추가" : "항목 편집")
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
            vm.updateItem(item, name: trimmed, icon: icon, context: modelContext)
        } else {
            vm.addItem(to: payload.routine, name: trimmed, icon: icon, context: modelContext)
        }
        dismiss()
    }
}
