//
//  BlockedAppsSection.swift
//  Anchor
//

import FamilyControls
import ManagedSettings
import SwiftData
import SwiftUI

struct BlockedAppsSection: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    @Bindable var routine: Routine

    @State private var selection = FamilyActivitySelection()
    @State private var showPicker = false
    @State private var authStatus: AuthorizationStatus = ShieldManager.authorizationStatus()
    @State private var authError: String?

    private var savedTokens: [ApplicationToken] {
        Array(ShieldManager.decodeSelection(routine.shieldSelectionData).applicationTokens)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("앱 차단")
                .font(.headline)
                .foregroundStyle(Color.anchorText(scheme))

            HStack(spacing: 10) {
                Button("권한") {
                    Task { await requestAuth() }
                }
                .buttonStyle(.bordered)
                .disabled(authStatus == .approved)

                Button(savedTokens.isEmpty ? "앱 선택" : "앱 수정") {
                    guard authStatus == .approved else { return }
                    syncSelectionFromRoutine()
                    showPicker = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.anchorAccent(scheme))
                .disabled(authStatus != .approved)
            }

            if !savedTokens.isEmpty {
                BlockedAppIconsRow(tokens: savedTokens, maxVisible: 10, iconSize: 32)
            }

            if let authError {
                Text(authError)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 6)
        .onAppear {
            authStatus = ShieldManager.authorizationStatus()
            syncSelectionFromRoutine()
        }
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                FamilyActivityPicker(selection: $selection)
                    .navigationTitle("차단할 앱")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("취소") {
                                syncSelectionFromRoutine()
                                showPicker = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("적용") {
                                applyAppSelection()
                                showPicker = false
                            }
                        }
                    }
            }
        }
    }

    private func syncSelectionFromRoutine() {
        selection = ShieldManager.decodeSelection(routine.shieldSelectionData)
    }

    private func applyAppSelection() {
        do {
            var merged = ShieldManager.decodeSelection(routine.shieldSelectionData)
            merged.applicationTokens = selection.applicationTokens
            try ShieldManager.saveSelection(merged, for: routine, modelContext: modelContext)
            authError = nil
            Task { await ShieldManager.refresh(modelContext: modelContext) }
        } catch {
            authError = "저장에 실패했습니다."
        }
    }

    private func requestAuth() async {
        do {
            try await ShieldManager.requestAuthorization()
            authStatus = ShieldManager.authorizationStatus()
            authError = nil
            await ShieldManager.refresh(modelContext: modelContext)
        } catch {
            authError = "권한 요청에 실패했습니다."
            authStatus = ShieldManager.authorizationStatus()
        }
    }
}
