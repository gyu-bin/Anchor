//
//  QuickLockAttributes.swift
//  Anchor
//

import ActivityKit
import Foundation

struct QuickLockAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var expiresAt: Date
        var appCount: Int
    }
}
