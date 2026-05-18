//
//  WebDomainBlocking.swift
//  Anchor
//

import Foundation
import ManagedSettings

/// Screen Time 웹 차단 — 피커 토큰(`shield.webDomains`)과 문자열 도메인(`webContent.blockedByFilter`)을 함께 씁니다.
enum WebDomainBlocking {
    static func managedDomains(from rawDomains: [String]) -> Set<WebDomain> {
        var result = Set<WebDomain>()
        for raw in rawDomains {
            for host in expandedHosts(from: raw) {
                result.insert(WebDomain(domain: host))
            }
        }
        return result
    }

    static func apply(
        to store: ManagedSettingsStore,
        webTokens: Set<WebDomainToken>,
        domainStrings: [String]
    ) {
        let managed = managedDomains(from: domainStrings)

        if webTokens.isEmpty {
            store.shield.webDomains = nil
        } else {
            store.shield.webDomains = webTokens
        }

        if managed.isEmpty {
            store.webContent.blockedByFilter = WebContentSettings.FilterPolicy.none
        } else {
            store.webContent.blockedByFilter = .specific(managed)
        }
    }

    static func clear(from store: ManagedSettingsStore) {
        store.shield.webDomains = nil
        store.webContent.blockedByFilter = WebContentSettings.FilterPolicy.none
    }

  private static func expandedHosts(from raw: String) -> [String] {
        let base = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .split(separator: "/").first.map(String.init) ?? ""

        guard !base.isEmpty else { return [] }

        var hosts = Set<String>()
        hosts.insert(base)

        if !base.hasPrefix("www.") {
            hosts.insert("www.\(base)")
        }

        switch base {
        case "youtube.com":
            hosts.insert("m.youtube.com")
            hosts.insert("youtu.be")
        case "instagram.com":
            hosts.insert("m.instagram.com")
        case "x.com":
            hosts.insert("twitter.com")
            hosts.insert("mobile.twitter.com")
        case "tiktok.com":
            hosts.insert("www.tiktok.com")
        case "netflix.com":
            hosts.insert("www.netflix.com")
        default:
            break
        }

        return Array(hosts)
    }
}
