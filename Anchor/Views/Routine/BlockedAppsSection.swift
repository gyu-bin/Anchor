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
    @EnvironmentObject private var premium: PremiumStore

    @Bindable var routine: Routine
    @Binding var paywallReason: PaywallReason?

    @State private var selection = FamilyActivitySelection()
    @State private var showPicker = false
    @State private var authStatus: AuthorizationStatus = ShieldManager.authorizationStatus()
    @State private var authError: String?

    private var savedTokens: [ApplicationToken] {
        Array(ShieldManager.decodeSelection(routine.shieldSelectionData).applicationTokens)
    }

    private var maxApps: Int {
        PremiumLimits.allowedAppCount(isPremium: premium.isPremium)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("앱 차단")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.anchorText(scheme))
                if !premium.isPremium {
                    Text(AppCopy.Premium.appLimitHint)
                        .font(.caption)
                        .foregroundStyle(Color.anchorSub(scheme))
                }
            }

            HStack(spacing: 10) {
                Button("권한") {
                    Task { await requestAuth() }
                }
                .buttonStyle(.bordered)
                .disabled(authStatus == .approved)
                .accessibilityLabel("Screen Time 권한 요청")

                Button(savedTokens.isEmpty ? "앱 선택" : "앱 수정") {
                    guard authStatus == .approved else { return }
                    syncSelectionFromRoutine()
                    showPicker = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.anchorAccent(scheme))
                .disabled(authStatus != .approved)
                .accessibilityLabel(savedTokens.isEmpty ? "차단할 앱 선택" : "차단 앱 수정")
            }

            if !savedTokens.isEmpty {
                BlockedAppIconsRow(tokens: savedTokens, maxVisible: 10, iconSize: 32)
                    .padding(.top, 2)
            }

            if let authError {
                BlockedInlineError(message: authError)
            }
        }
        .onAppear {
            authStatus = ShieldManager.authorizationStatus()
            syncSelectionFromRoutine()
        }
        .sheet(isPresented: $showPicker) {
            FamilyActivityPickerSheet(
                selection: $selection,
                isPresented: $showPicker,
                title: "차단할 앱",
                onApply: applyAppSelection,
                onCancelSync: syncSelectionFromRoutine
            )
        }
    }

    private func syncSelectionFromRoutine() {
        selection = ShieldManager.decodeSelection(routine.shieldSelectionData)
    }

    private func applyAppSelection() {
        let count = selection.applicationTokens.count
        if !premium.isPremium && count > maxApps {
            paywallReason = .appLimit
            return
        }
        do {
            var merged = ShieldManager.decodeSelection(routine.shieldSelectionData)
            merged.applicationTokens = selection.applicationTokens
            try ShieldManager.saveSelection(merged, for: routine, modelContext: modelContext)
            authError = nil
            RoutineSync.afterMutation(modelContext: modelContext)
        } catch {
            authError = AppCopy.Error.saveFailed
        }
    }

    private func requestAuth() async {
        do {
            try await ShieldManager.requestAuthorization()
            authStatus = ShieldManager.authorizationStatus()
            authError = nil
            RoutineSync.afterMutation(modelContext: modelContext)
        } catch {
            authError = AppCopy.Error.permissionFailed
            authStatus = ShieldManager.authorizationStatus()
        }
    }
}
