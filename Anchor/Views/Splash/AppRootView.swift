//
//  AppRootView.swift
//  Anchor
//

import SwiftData
import SwiftUI

/// SwiftData 로딩 전에도 스플래시를 즉시 보여 줍니다.
struct AppRootView: View {
    @EnvironmentObject private var premium: PremiumStore

    @State private var modelContainer: ModelContainer?
    @State private var isReadyForMain = false

    var body: some View {
        Group {
            if isReadyForMain, let modelContainer {
                ContentView()
                    .modelContainer(modelContainer)
            } else {
                SplashStaticView()
            }
        }
        .task {
            await prepareForMain()
        }
    }

    @MainActor
    private func prepareForMain() async {
        let minimumSplash: TimeInterval = 1.0
        let started = Date()

        async let containerTask: ModelContainer? = Task.detached(priority: .userInitiated) {
            AppModelContainer.make()
        }.value
        async let premiumTask: Void = premium.bootstrap()

        let loadedContainer = await containerTask
        _ = await premiumTask

        let elapsed = Date().timeIntervalSince(started)
        if elapsed < minimumSplash {
            try? await Task.sleep(for: .seconds(minimumSplash - elapsed))
        }

        modelContainer = loadedContainer ?? AppModelContainer.make()
        isReadyForMain = true
    }
}
