//
//  ShieldActionExtension.swift
//  AnchorShieldAction
//

import Foundation
import ManagedSettings

final class ShieldActionExtension: ShieldActionDelegate {
    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    private func handleAction(
        _ action: ShieldAction,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.defer)
        case .secondaryButtonPressed:
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                completionHandler(.close)
            }
        @unknown default:
            completionHandler(.defer)
        }
    }
}
