//
//  TabRouter.swift
//  Anchor
//

import Combine
import SwiftUI

@MainActor
final class TabRouter: ObservableObject {
    @Published var selectedTab: Int = 0

    /// 다른 탭에서 「루틴 만들기」 후 루틴 탭이 열릴 때 새 카드를 펼칩니다.
    @Published private(set) var pendingCreateRoutine = false
    @Published private(set) var pendingExpandRoutineID: UUID?

    func openToday() {
        selectedTab = 0
    }

    func openRoutines(andCreateNew: Bool = false) {
        if andCreateNew {
            pendingExpandRoutineID = nil
            pendingCreateRoutine = true
        }
        selectedTab = 1
    }

    /// 루틴 탭에서만 호출 — 대기 중인 「새 루틴」 생성을 한 번 소비합니다.
    func consumePendingCreateRoutine() -> Bool {
        guard pendingCreateRoutine else { return false }
        pendingCreateRoutine = false
        pendingExpandRoutineID = nil
        return true
    }

    /// 루틴 탭에서만 호출 — 펼칠 루틴 ID를 한 번 소비합니다.
    func consumePendingExpandRoutineID() -> UUID? {
        let id = pendingExpandRoutineID
        pendingExpandRoutineID = nil
        return id
    }

    func openHistory() {
        selectedTab = 2
    }

    func openSettings() {
        selectedTab = 3
    }
}
