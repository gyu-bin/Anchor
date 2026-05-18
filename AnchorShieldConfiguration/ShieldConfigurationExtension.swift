//
//  ShieldConfigurationExtension.swift
//  AnchorShieldConfiguration
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

private enum ShieldCopy {
    static let appGroupID = "group.com.rbqls6651.anchor"
    static let titleKey = "shield.title"
    static let subtitleKey = "shield.subtitle"

    static var title: String {
        UserDefaults(suiteName: appGroupID)?.string(forKey: titleKey)
            ?? "루틴을 먼저 완료해 주세요"
    }

    static var subtitle: String {
        UserDefaults(suiteName: appGroupID)?.string(forKey: subtitleKey)
            ?? "끝나면 바로 열어 드릴게요"
    }
}

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfig(title: ShieldCopy.title, subtitle: ShieldCopy.subtitle)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfig(title: ShieldCopy.title, subtitle: ShieldCopy.subtitle)
    }

    private func makeConfig(title: String, subtitle: String) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor(red: 245 / 255, green: 240 / 255, blue: 232 / 255, alpha: 1),
            icon: UIImage(systemName: "key.fill"),
            title: ShieldConfiguration.Label(
                text: title,
                color: UIColor(red: 26 / 255, green: 26 / 255, blue: 26 / 255, alpha: 1)
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "키링 열기",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 74 / 255, green: 103 / 255, blue: 65 / 255, alpha: 1),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "그래도 열기 (5초 후)",
                color: .tertiaryLabel
            )
        )
    }
}
