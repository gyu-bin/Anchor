//
//  AddRoutineSheet.swift
//  Anchor
//

import SwiftData
import SwiftUI

struct AddRoutineSheet: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    let onSave: (String, Date) -> Void

    @State private var name: String = ""
    @State private var startTime: Date = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("루틴 이름") {
                    TextField("예: 출근 전 루틴", text: $name)
                }
                Section("시작 시간") {
                    DatePicker("알림 시각", selection: $startTime, displayedComponents: .hourAndMinute)
                        .environment(\.locale, Locale(identifier: "ko_KR"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.anchorBg(scheme))
            .navigationTitle("루틴 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        onSave(name, startTime)
                        dismiss()
                    }
                }
            }
        }
    }
}
