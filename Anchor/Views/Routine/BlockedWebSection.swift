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

    @Bindable var routine: Routine
    @Binding var paywallReason: PaywallReason?
    @StateObject private var vm = RoutineViewModel()

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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("웹 차단")
                .font(.headline)
                .foregroundStyle(Color.anchorText(scheme))

            if !premium.isPremium {
                Text(AppCopy.Premium.webLimitHint)
                    .font(.caption)
                    .foregroundStyle(Color.anchorSub(scheme))
            }

            HStack(spacing: 10) {
                Button(savedWebTokens.isEmpty ? "사이트 선택" : "사이트 수정") {
                    syncSelectionFromRoutine()
                    showPicker = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.anchorAccent(scheme))
                .disabled(ShieldManager.authorizationStatus() != .approved)
            }

            if !savedWebTokens.isEmpty {
                BlockedWebIconsRow(tokens: savedWebTokens, maxVisible: 10, iconSize: 32)
            }

            HStack(spacing: 10) {
                TextField("도메인", text: $domainInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(Color.anchorSubBg(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Button("추가") {
                    addDomain(domainInput)
                }
                .buttonStyle(.bordered)
                .disabled(vm.normalizeDomain(domainInput).isEmpty)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { domain in
                        presetChip(domain)
                    }
                }
            }

            if !routine.blockedWebs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(routine.blockedWebs, id: \.self) { web in
                            HStack(spacing: 6) {
                                BlockedDomainIconBadge(domain: web)
                                Button {
                                    vm.removeBlockedWeb(web, from: routine, context: modelContext)
                                    Task { await ShieldManager.refresh(modelContext: modelContext) }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.anchorSub(scheme))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                FamilyActivityPicker(selection: $selection)
                    .navigationTitle("차단할 웹사이트")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("취소") {
                                syncSelectionFromRoutine()
                                showPicker = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("적용") {
                                applyWebSelection()
                                showPicker = false
                            }
                        }
                    }
            }
        }
    }

    private func addDomain(_ raw: String) {
        let domain = vm.normalizeDomain(raw)
        guard !domain.isEmpty else { return }
        if routine.blockedWebs.contains(domain) { return }
        guard PremiumLimits.canAddWebDomain(
            currentCount: routine.blockedWebs.count,
            isPremium: premium.isPremium
        ) else {
            paywallReason = .webLimit
            return
        }
        vm.addBlockedWeb(raw, to: routine, context: modelContext)
        domainInput = ""
        Task { await ShieldManager.refresh(modelContext: modelContext) }
    }

    private func presetChip(_ domain: String) -> some View {
        let added = routine.blockedWebs.contains(domain)
        return Button {
            if added {
                vm.removeBlockedWeb(domain, from: routine, context: modelContext)
            } else {
                addDomain(domain)
            }
            Task { await ShieldManager.refresh(modelContext: modelContext) }
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
    }

    private func syncSelectionFromRoutine() {
        selection = ShieldManager.decodeSelection(routine.shieldSelectionData)
    }

    private func applyWebSelection() {
        var merged = ShieldManager.decodeSelection(routine.shieldSelectionData)
        merged.webDomainTokens = selection.webDomainTokens
        try? ShieldManager.saveSelection(merged, for: routine, modelContext: modelContext)
        Task { await ShieldManager.refresh(modelContext: modelContext) }
    }
}
