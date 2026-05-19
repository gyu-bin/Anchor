//
//  BlockedWebSection.swift
//  Anchor
//

import FamilyControls
import ManagedSettings
import SwiftData
import SwiftUI

struct BlockedWebSection: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var premium: PremiumStore
    @Environment(RoutineViewModel.self) private var routineVM

    @Bindable var routine: Routine
    @Binding var paywallReason: PaywallReason?

    @State private var selection = FamilyActivitySelection()
    @State private var showPicker = false
    @State private var domainInput: String = ""

    private let presets: [String] = [
        "youtube.com",
        "instagram.com",
        "x.com",
        "tiktok.com",
        "netflix.com",
    ]

    private var savedWebTokens: [WebDomainToken] {
        Array(ShieldManager.decodeSelection(routine.shieldSelectionData).webDomainTokens)
    }

    private var blockedDomains: [String] {
        routine.resolvedBlockedWebs(in: modelContext)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("웹 차단")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.anchorText(scheme))
                if !premium.isPremium {
                    Text(AppCopy.Premium.webLimitHint)
                        .font(.caption)
                        .foregroundStyle(Color.anchorSub(scheme))
                }
            }

            Button(savedWebTokens.isEmpty ? "사이트 선택" : "사이트 수정") {
                syncSelectionFromRoutine()
                showPicker = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.anchorAccent(scheme))
            .frame(maxWidth: .infinity, alignment: .leading)
            .disabled(ShieldManager.authorizationStatus() != .approved)
            .accessibilityLabel(savedWebTokens.isEmpty ? "차단할 웹사이트 선택" : "차단 웹사이트 수정")

            if !savedWebTokens.isEmpty {
                BlockedWebIconsRow(tokens: savedWebTokens, maxVisible: 10, iconSize: 32)
            }

            HStack(spacing: 10) {
                TextField("도메인", text: $domainInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color.anchorSubBg(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Button("추가") {
                    addDomain(domainInput)
                }
                .buttonStyle(.bordered)
                .disabled(routineVM.normalizeDomain(domainInput).isEmpty)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { domain in
                        presetChip(domain)
                    }
                }
            }

            if !blockedDomains.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(blockedDomains, id: \.self) { web in
                            HStack(spacing: 6) {
                                BlockedDomainIconBadge(domain: web)
                                Button {
                                    routineVM.removeBlockedWeb(web, from: routine, context: modelContext)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.anchorSub(scheme))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(web) 삭제")
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            FamilyActivityPickerSheet(
                selection: $selection,
                isPresented: $showPicker,
                title: "차단할 웹사이트",
                onApply: applyWebSelection,
                onCancelSync: syncSelectionFromRoutine
            )
        }
    }

    private func addDomain(_ raw: String) {
        let domain = routineVM.normalizeDomain(raw)
        guard !domain.isEmpty else { return }
        if blockedDomains.contains(domain) { return }
        guard PremiumLimits.canAddWebDomain(
            currentCount: blockedDomains.count,
            isPremium: premium.isPremium
        ) else {
            paywallReason = .webLimit
            return
        }
        routineVM.addBlockedWeb(raw, to: routine, context: modelContext)
        domainInput = ""
    }

    private func presetChip(_ domain: String) -> some View {
        let added = blockedDomains.contains(domain)
        return Button {
            if added {
                routineVM.removeBlockedWeb(domain, from: routine, context: modelContext)
            } else {
                addDomain(domain)
            }
        } label: {
            Text(BlockedDomainStyle.displayTitle(for: domain))
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(added ? Color.anchorAccent(scheme).opacity(0.18) : Color.anchorSubBg(scheme))
                .foregroundStyle(Color.anchorText(scheme))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(BlockedDomainStyle.displayTitle(for: domain)) \(added ? "제거" : "추가")")
    }

    private func syncSelectionFromRoutine() {
        selection = ShieldManager.decodeSelection(routine.shieldSelectionData)
    }

    private func applyWebSelection() {
        var merged = ShieldManager.decodeSelection(routine.shieldSelectionData)
        merged.webDomainTokens = selection.webDomainTokens
        try? ShieldManager.saveSelection(merged, for: routine, modelContext: modelContext)
        RoutineSync.afterMutation(modelContext: modelContext)
    }
}
