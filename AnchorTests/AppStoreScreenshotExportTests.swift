//
//  AppStoreScreenshotExportTests.swift
//  AnchorTests
//

import Foundation
import Testing
@testable import Keyring

@MainActor
struct AppStoreScreenshotExportTests {
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
