//
//  AppStorePaywallFromSettingsExportView.swift
//  Anchor
//

import SwiftData
import SwiftUI

/// 설정 → 「전체 기능 열기」 탭 시 나오는 시트 (IAP 심사·마케팅 캡처용).
struct AppStorePaywallFromSettingsExportView: View {
    let seed: AppStoreScreenshotData.Seed

    @StateObject private var premium = PremiumStore()
    @State private var showPaywall = true

    var body: some View {
        AppStoreScreenshotHost(
            screen: .settings,
            expandedRoutineIDs: []
        )
        .modelContainer(seed.container)
        .environmentObject(premium)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showPaywall) {
            PaywallSheet(reason: .general)
                .environmentObject(premium)
                .interactiveDismissDisabled(true)
        }
        .onAppear {
            UserDefaults.standard.set(true, forKey: AppGuideStorage.hasSeenGuideKey)
            PremiumStorage.setPurchased(false)
            premium.previewShowsPurchaseUI = true
            premium.errorMessage = nil
            showPaywall = true
        }
    }
}
