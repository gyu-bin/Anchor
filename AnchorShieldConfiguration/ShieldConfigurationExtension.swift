//
//  ShieldConfigurationExtension.swift
//  AnchorShieldConfiguration
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

private enum ShieldMessagePresets {
    static let pairs: [(title: String, subtitle: String)] = [
        ("오늘 루틴을 먼저 마쳐 주세요", "다 하시면 바로 열어 드릴게요"),
        ("잠깐만, 루틴이 먼저예요", "체크 끝나면 이 앱도 쓸 수 있어요"),
        ("키링 루틴이 남아 있어요", "완료하면 잠금이 풀려요"),
    ]

    static var random: (title: String, subtitle: String) {
        pairs.randomElement() ?? pairs[0]
    }
}

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        let message = ShieldMessagePresets.random
        return makeConfig(title: message.title, subtitle: message.subtitle)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        let message = ShieldMessagePresets.random
        return makeConfig(title: message.title, subtitle: message.subtitle)
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
