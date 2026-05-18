//
//  AnchorWidgetBundle.swift
//  AnchorWidget
//

import SwiftUI
import WidgetKit

@main
struct AnchorWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayProgressWidget()
        LockStatusWidget()
    }
}
