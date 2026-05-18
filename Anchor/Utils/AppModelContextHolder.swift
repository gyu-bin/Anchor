//
//  AppModelContextHolder.swift
//  Anchor
//

import SwiftData

@MainActor
enum AppModelContextHolder {
    static weak var main: ModelContext?
}
