//
//  AppStoreScreenshotExporter.swift
//  Anchor
//

import SwiftData
import SwiftUI
import UIKit

enum AppStoreScreenshotExporter {
    struct ExportResult: Sendable {
        let directory: URL
        let files: [URL]
    }

    @MainActor
    static func exportAll(to directory: URL? = nil) throws -> ExportResult {
        let wasPremium = PremiumStorage.isPurchased
        PremiumStorage.setPurchased(true)
        defer { PremiumStorage.setPurchased(wasPremium) }

        let seed = try AppStoreScreenshotData.makeSeed()
        let outDir = directory ?? defaultOutputDirectory()
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        var written: [URL] = []
        for screen in AppStoreScreenshotHost.Screen.allCases {
            let expanded: Set<UUID> = screen == .routine ? [seed.primaryRoutineID] : []
            let view = AppStoreScreenshotHost(screen: screen, expandedRoutineIDs: expanded)
                .modelContainer(seed.container)
                .frame(
                    width: AppStoreScreenshotData.exportWidth,
                    height: AppStoreScreenshotData.exportHeight
                )

            let renderer = ImageRenderer(content: view)
            renderer.scale = AppStoreScreenshotData.exportScale
            renderer.isOpaque = true

            guard let image = renderer.uiImage,
                  let data = image.pngData()
            else {
                throw ExportError.renderFailed(screen.rawValue)
            }

            let url = outDir.appendingPathComponent("\(screen.rawValue).png")
            try data.write(to: url, options: .atomic)
            written.append(url)
        }

        return ExportResult(directory: outDir, files: written)
    }

    @MainActor
    static func export(
        screens: [AppStoreScreenshotHost.Screen],
        to directory: URL
    ) throws -> ExportResult {
        let wasPremium = PremiumStorage.isPurchased
        PremiumStorage.setPurchased(true)
        UserDefaults.standard.set(true, forKey: AppGuideStorage.hasSeenGuideKey)
        defer { PremiumStorage.setPurchased(wasPremium) }

        let seed = try AppStoreScreenshotData.makeSeed()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var written: [URL] = []
        for screen in screens {
            let expanded: Set<UUID> = screen == .routine ? [seed.primaryRoutineID] : []
            let view = AppStoreScreenshotHost(screen: screen, expandedRoutineIDs: expanded)
                .modelContainer(seed.container)
                .frame(
                    width: AppStoreScreenshotData.exportWidth,
                    height: AppStoreScreenshotData.exportHeight
                )

            let renderer = ImageRenderer(content: view)
            renderer.scale = AppStoreScreenshotData.exportScale
            renderer.isOpaque = true

            guard let image = renderer.uiImage,
                  let data = image.pngData()
            else {
                throw ExportError.renderFailed(screen.rawValue)
            }

            let url = directory.appendingPathComponent("\(screen.rawValue).png")
            try data.write(to: url, options: .atomic)
            written.append(url)
        }

        return ExportResult(directory: directory, files: written)
    }

    /// 시뮬레이터 앱 Documents — `simctl get_app_container`로 Mac에 복사합니다.
    static func simulatorDocumentsOutputDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("AppStoreScreenshots", isDirectory: true)
    }

    static func defaultOutputDirectory() -> URL {
        if let override = ProcessInfo.processInfo.environment["APP_STORE_SCREENSHOTS_DIR"],
           !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return repoRoot.appendingPathComponent("Marketing/AppStore/Screenshots/raw", isDirectory: true)
    }

    static let launchArgument = AppStoreScreenshotLaunch.flag

    enum ExportError: Error, CustomStringConvertible {
        case renderFailed(String)

        var description: String {
            switch self {
            case .renderFailed(let screen):
                "스크린샷 렌더 실패: \(screen)"
            }
        }
    }
}
