//
//  AppInfo.swift
//  Anchor
//

import Foundation

enum AppInfo {
    static var marketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static var versionLabel: String {
        "\(marketingVersion) (\(buildNumber))"
    }

    static let privacyPolicyURL = URL(string: "https://keyring.app/privacy")!
}
