//
//  AppRootView.swift
//  Anchor
//

import SwiftData
import SwiftUI

/// SwiftData 로딩 전에도 스플래시를 즉시 보여 줍니다.
struct AppRootView: View {
    @EnvironmentObject private var tabRouter: TabRouter
    @EnvironmentObject private var premium: PremiumStore

    @State private var modelContainer: ModelContainer?
    @State private var splashDismissed = false

    private var canShowMain: Bool {
        splashDismissed && modelContainer != nil
    }

    var body: some View {
        Group {
            if canShowMain, let modelContainer {
                ContentView()
                    .modelContainer(modelContainer)
            } else if !splashDismissed {
                PremiumFocusSplash {
                    splashDismissed = true
                }
            } else {
                SplashStaticView()
            }
        }
        .task {
            await loadModelContainerIfNeeded()
            await premium.bootstrap()
        }
    }

    @MainActor
    private func loadModelContainerIfNeeded() async {
        guard modelContainer == nil else { return }
        modelContainer = await Task.detached(priority: .userInitiated) {
            AppModelContainer.make()
        }.value
    }
}
