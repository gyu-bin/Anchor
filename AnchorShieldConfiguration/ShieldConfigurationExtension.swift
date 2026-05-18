//
//  ShieldConfigurationExtension.swift
//  AnchorShieldConfiguration
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfig(
            title: "루틴을 먼저 완료해보세요",
            subtitle: "키링에서 루틴을 완료하면 바로 열려요"
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfig(
            title: "루틴을 먼저 완료해보세요",
            subtitle: "이 카테고리는 루틴 완료 후 사용 가능해요"
        )
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
