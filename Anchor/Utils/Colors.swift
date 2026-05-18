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
        _ = scheme
        return Color(hex: "1A1A1A")
    }

    static func anchorSub(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return Color(hex: "6B6560")
    }

    static func anchorBorder(_ scheme: ColorScheme) -> Color {
        _ = scheme
        return Color(hex: "E0D9CF")
    }

    static let anchorSuccess = Color.green
    static let anchorDanger = Color.red
    static let anchorInfo = Color.blue
}
