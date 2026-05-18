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
    @StateObject private var premiumStore = PremiumStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(tabRouter)
                .environmentObject(premiumStore)
        }
    }
}

enum AppModelContainer {
    private static let appGroupID = "group.com.rbqls6651.anchor"

    static func make() -> ModelContainer {
        let schema = Schema([
            Routine.self,
            RoutineItem.self,
            DailyLog.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain, nsError.code == 134110 {
                removePersistedStoreFiles()
                do {
                    return try ModelContainer(for: schema, configurations: [config])
                } catch {
                    fatalError("SwiftData 컨테이너를 복구한 뒤에도 열 수 없습니다: \(error)")
                }
            }
            fatalError("SwiftData 컨테이너를 만들 수 없습니다: \(error)")
        }
    }

    /// 마이그레이션 실패로 열리지 않는 SQLite 저장소를 제거합니다 (시뮬레이터·개발 복구용).
    private static func removePersistedStoreFiles() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else { return }

        let support = containerURL.appendingPathComponent("Library/Application Support", isDirectory: true)
        let names = ["default.store", "default.store-shm", "default.store-wal"]
        for name in names {
            try? FileManager.default.removeItem(at: support.appendingPathComponent(name))
        }
    }
}
