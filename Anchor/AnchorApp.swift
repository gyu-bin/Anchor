//
//  AnchorApp.swift
//  Anchor
//

import SwiftData
import SwiftUI

@main
struct AnchorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var tabRouter = TabRouter()

    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Routine.self,
            RoutineItem.self,
            DailyLog.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData 컨테이너를 만들 수 없습니다: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tabRouter)
                .modelContainer(sharedModelContainer)
        }
    }
}
