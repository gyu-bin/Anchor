//
//  AnchorAppIntents.swift
//  Anchor
//

import AppIntents
import Foundation

private enum IntentFlags {
    static let openToday = "intent.openToday"
    static let completeNext = "intent.completeNext"
    static let suite = SharedShieldStore.suite
}

struct OpenTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "오늘 루틴 열기"
    static var description = IntentDescription("오늘 탭을 엽니다.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        IntentFlags.suite?.set(true, forKey: IntentFlags.openToday)
        return .result()
    }
}

struct CompleteNextItemIntent: AppIntent {
    static var title: LocalizedStringResource = "다음 항목 완료"
    static var description = IntentDescription("아직 끝내지 않은 첫 항목을 완료 처리합니다.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        IntentFlags.suite?.set(true, forKey: IntentFlags.completeNext)
        IntentFlags.suite?.set(true, forKey: IntentFlags.openToday)
        NotificationCenter.default.post(name: .anchorCompleteNextItem, object: nil)
        return .result()
    }
}

struct AnchorShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenTodayIntent(),
            phrases: [
                "\(.applicationName) 오늘",
                "오늘 루틴 in \(.applicationName)",
            ],
            shortTitle: "오늘",
            systemImageName: "sun.max.fill"
        )
        AppShortcut(
            intent: CompleteNextItemIntent(),
            phrases: [
                "\(.applicationName) 다음 항목",
                "다음 루틴 완료 in \(.applicationName)",
            ],
            shortTitle: "다음 항목",
            systemImageName: "checkmark.circle"
        )
    }
}

enum IntentRouter {
    @MainActor
    static func consumeOpenToday() -> Bool {
        guard IntentFlags.suite?.bool(forKey: IntentFlags.openToday) == true else { return false }
        IntentFlags.suite?.removeObject(forKey: IntentFlags.openToday)
        return true
    }

    @MainActor
    static func consumeCompleteNext() -> Bool {
        guard IntentFlags.suite?.bool(forKey: IntentFlags.completeNext) == true else { return false }
        IntentFlags.suite?.removeObject(forKey: IntentFlags.completeNext)
        return true
    }
}
