//
//  PaywallSheet.swift
//  Anchor
//

import StoreKit
import SwiftUI

struct PaywallSheet: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var premium: PremiumStore

    let reason: PaywallReason

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppCopy.Premium.title)
                            .font(.title2.bold())
                            .foregroundStyle(Color.anchorText(scheme))
                        Text(reasonMessage)
                            .font(.subheadline)
                            .foregroundStyle(Color.anchorSub(scheme))
                    }

                    AnchorCard {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(AppCopy.Premium.benefits, id: \.self) { line in
                                Label(line, systemImage: "checkmark.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.anchorText(scheme))
                                    .symbolRenderingMode(.hierarchical)
                                    .tint(Color.anchorAccent(scheme))
                            }
                        }
                        .padding(AnchorLayout.cardPadding)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(AppCopy.Premium.freeTierTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.anchorSub(scheme))
                        Text(AppCopy.Premium.freeTierSummary)
                            .font(.caption)
                            .foregroundStyle(Color.anchorSub(scheme))
                    }

                    if premium.isLoading, premium.product == nil {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text(AppCopy.Premium.loadingProduct)
                                .font(.caption)
                                .foregroundStyle(Color.anchorSub(scheme))
                        }
                    }

                    if premium.productLoadFailed, premium.product == nil, !premium.isLoading {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(AppCopy.Premium.productUnavailable)
                                .font(.caption)
                                .foregroundStyle(.red)
                            Button(AppCopy.Premium.retryLoad) {
                                Task { await premium.ensureProductLoaded() }
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.anchorAccent(scheme))
                        }
                    }

                    if let error = premium.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await premium.purchase() }
                    } label: {
                        HStack {
                            if premium.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(purchaseButtonTitle)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AnchorButtonStyle())
                    .disabled(premium.isLoading || premium.isPremium || premium.product == nil)

                    Button(AppCopy.Premium.restore) {
                        Task { await premium.restore() }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.anchorAccent(scheme))
                    .frame(maxWidth: .infinity)
                    .disabled(premium.isLoading)

                    Text(AppCopy.Premium.footnote)
                        .font(.caption2)
                        .foregroundStyle(Color.anchorSub(scheme))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(AnchorLayout.screenHorizontal)
                .padding(.vertical, 8)
            }
            .anchorScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppCopy.Common.cancel) { dismiss() }
                }
            }
            .onChange(of: premium.isPremium) { _, unlocked in
                if unlocked { dismiss() }
            }
            .task {
                premium.errorMessage = nil
                await premium.ensureProductLoaded()
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(28)
    }

    private var reasonMessage: String {
        switch reason {
        case .routineLimit: return AppCopy.Premium.reasonRoutine
        case .itemLimit: return AppCopy.Premium.reasonItem
        case .appLimit: return AppCopy.Premium.reasonApp
        case .webLimit: return AppCopy.Premium.reasonWeb
        case .history: return AppCopy.Premium.reasonHistory
        case .shieldMessage: return AppCopy.Premium.reasonShield
        case .weeklyNotification: return AppCopy.Premium.reasonWeekly
        case .general: return AppCopy.Premium.reasonGeneral
        }
    }

    private var purchaseButtonTitle: String {
        if premium.isPremium { return AppCopy.Premium.alreadyUnlocked }
        if let price = premium.product?.displayPrice {
            return AppCopy.Premium.purchase(price: price)
        }
        return AppCopy.Premium.purchase(price: PremiumLimits.displayPriceKRW)
    }
}
