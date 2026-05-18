//
//  TabRouter.swift
//  Anchor
//

import Combine
import SwiftUI

@MainActor
final class TabRouter: ObservableObject {
    @Published var selectedTab: Int = 0

    func openToday() {
        selectedTab = 0
    }
}
