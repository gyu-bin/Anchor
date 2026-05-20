
//
//  TempUnlockAttributes.swift
//  Anchor
//
//  AnchorWidget/TempUnlockAttributes.swift 와 동일한 구조여야 합니다.
//

import ActivityKit
import Foundation

struct TempUnlockAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var expiresAt: Date
    }
}
