//
//  AnchorMotion.swift
//  Anchor
//

import SwiftUI
import UIKit

enum AnchorMotion {
    static var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    static func spring(response: Double = 0.32, dampingFraction: Double = 0.82) -> Animation {
        prefersReducedMotion
            ? .easeInOut(duration: 0.22)
            : .spring(response: response, dampingFraction: dampingFraction)
    }
}

extension View {
    func anchorSpringAnimation<V: Equatable>(
        _ value: V,
        response: Double = 0.32,
        dampingFraction: Double = 0.82
    ) -> some View {
        animation(AnchorMotion.spring(response: response, dampingFraction: dampingFraction), value: value)
    }
}
