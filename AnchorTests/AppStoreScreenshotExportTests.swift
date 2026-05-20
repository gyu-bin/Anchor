//
//  AppStoreScreenshotExportTests.swift
//  AnchorTests
//

import Foundation
import Testing
@testable import Keyring

@MainActor
struct AppStoreScreenshotExportTests {
    /// `Marketing/AppStore/Screenshots/app-store-2` — 가이드 3장 (TestFlight 없음).
    @Test func exportGuideScreensForAppStore2() throws {
        let outDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("keyring-guide-export", isDirectory: true)
        let result = try AppStoreScreenshotExporter.export(
            screens: [.guideMorning, .guideEvening, .guideStart],
            to: outDir
        )
        #expect(result.files.count == 3)

        let moves: [(String, String)] = [
            ("guideMorning.png", "01-guide-morning.png"),
            ("guideEvening.png", "02-guide-evening.png"),
            ("guideStart.png", "03-guide-start-paywall.png"),
        ]
        let marketingDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Marketing/AppStore/Screenshots/app-store-2", isDirectory: true)
        try FileManager.default.createDirectory(at: marketingDir, withIntermediateDirectories: true)

        for (from, to) in moves {
            let src = outDir.appendingPathComponent(from)
            let dest = marketingDir.appendingPathComponent(to)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.copyItem(at: src, to: dest)
        }
    }

    /// `Scripts/export_app_store_screenshots.sh` 또는 Xcode에서 이 테스트만 실행하세요.
    @Test func exportAppStoreScreenshots() throws {
        let result = try AppStoreScreenshotExporter.exportAll()
        #expect(result.files.count == AppStoreScreenshotHost.Screen.allCases.count)
        for url in result.files {
            #expect(FileManager.default.fileExists(atPath: url.path))
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            let size = (attrs[.size] as? Int) ?? 0
            #expect(size > 10_000)
        }
    }
}
