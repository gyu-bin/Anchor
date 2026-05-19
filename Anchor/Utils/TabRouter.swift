//
//  TabRouter.swift
//  Anchor
//

import Combine
import SwiftUI

@MainActor
final class TabRouter: ObservableObject {
    @Published var selectedTab: Int = 0

    /// 오늘·기록 등 다른 탭에서 「루틴 만들기」 후 루틴 탭이 열릴 때 새 카드를 펼칩니다.
    private(set) var pendingCreateRoutine = false

    func openToday() {
        selectedTab = 0
    }

    func openRoutines(andCreateNew: Bool = false) {
        if andCreateNew {
            pendingCreateRoutine = true
        }
        selectedTab = 1
    }

    /// 루틴 탭에서만 호출 — 대기 중인 「새 루틴」 생성을 한 번 소비합니다.
    func consumePendingCreateRoutine() -> Bool {
        guard pendingCreateRoutine else { return false }
        pendingCreateRoutine = false
        return true
    }

    func openHistory() {
        selectedTab = 2
    }

    func openSettings() {
        selectedTab = 3
    }
}
