//
//  Colors.swift
//  Anchor
//

import SwiftUI

extension Color {
    static func anchorBg(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return Color("AnchorBackground")
    }

    static func anchorCard(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return Color("AnchorCard")
    }

    static func anchorSubBg(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return Color("AnchorSubBg")
    }

    static func anchorAccent(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return Color("AnchorAccent")
    }

    static func anchorText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "F2EDE6") : Color(hex: "1C1C1E")
    }

    static func anchorSub(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "A8A39C") : Color(hex: "8E8A84")
    }

    static func anchorBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "3A3834") : Color(hex: "E8E4DD")
    }

    static func anchorSuccess(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return Color(hex: "3D8B5A")
    }

    static func anchorWarning(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return Color(hex: "D4843A")
    }

    static func anchorHighlight(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return Color.anchorAccent(scheme).opacity(0.1)
    }

    static let anchorDanger = Color(hex: "D64545")
}
