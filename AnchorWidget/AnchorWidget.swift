//
//  AnchorWidget.swift
//  AnchorWidget
//
//  위젯 확장 전체에서 공유하는 Intent와 ProgressRing 뷰.
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Intent
// perform()이 앱을 열면 ContentView.consumeIntentFlags()가
// IntentRouter.consumeCompleteNext() 플래그를 읽고 다음 항목을 완료 처리합니다.
struct AnchorCompleteNextIntent: AppIntent {
    static var title: LocalizedStringResource = "다음 항목 완료"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        let s = UserDefaults(suiteName: "group.com.rbqls6651.anchor")
        s?.set(true, forKey: "intent.completeNext")
        s?.set(true, forKey: "intent.openToday")
        return .result()
    }
}

// MARK: - Progress Ring
struct WidgetProgressRing: View {
    let progress: Int       // 0–100
    let lineWidth: CGFloat
    let fontSize: CGFloat

    private var fraction: CGFloat { CGFloat(min(max(progress, 0), 100)) / 100 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color("AnchorAccent").opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    Color("AnchorAccent"),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(progress)%")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(Color("AnchorAccent"))
        }
    }
}
