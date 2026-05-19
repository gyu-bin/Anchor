//
//  AnchorWidgetBundle.swift
//  AnchorWidget
//

import SwiftUI
import WidgetKit

@main
struct AnchorWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayProgressWidget()   // 홈 화면 small/medium
        LockStatusWidget()      // 잠금화면 inline/circular/rectangular
    }
}
