//
//  PremiumStore.swift
//  Anchor
//

import Combine
import Foundation
import StoreKit

enum PaywallReason: String, Identifiable {
    case routineLimit
    case itemLimit
    case appLimit
    case webLimit
    case history
    case weeklyNotification
    case general

    var id: String { rawValue }
}

@MainActor
final class PremiumStore: ObservableObject {
    @Published private(set) var isPremium: Bool = PremiumStorage.isPremium
    @Published private(set) var product: Product?
    @Published private(set) var isLoading = false
    @Published private(set) var productLoadFailed = false
    @Published var errorMessage: String?
    /// App Store 심사 스크린샷 — StoreKit 없이 ₩7,900 구매 UI 표시
    @Published var previewShowsPurchaseUI = false

    func bootstrap() async {
        isPremium = PremiumStorage.isPremium
        await refreshEntitlements()
        await loadProduct()
        listenForTransactions()
    }

    /// Paywall이 열릴 때 상품 정보를 다시 불러옵니다.
    func ensureProductLoaded() async {
        if product != nil {
            productLoadFailed = false
            return
        }
        isLoading = true
        defer { isLoading = false }
        await loadProduct()
    }

    func loadProduct() async {
        productLoadFailed = false
        do {
            let products = try await Product.products(for: [PremiumLimits.productID])
            product = products.first
            productLoadFailed = products.isEmpty
            if products.isEmpty {
                #if DEBUG
                print("[PremiumStore] Product.products returned empty for \(PremiumLimits.productID). Check Scheme → Run → StoreKit Configuration = Products.storekit, then clean build & rerun.")
                #endif
            }
        } catch {
            product = nil
            productLoadFailed = true
            #if DEBUG
            print("[PremiumStore] loadProduct failed: \(error)")
            #endif
        }
    }

    func purchase() async {
        if product == nil {
            await loadProduct()
        }
        guard let product else {
            errorMessage = AppCopy.Premium.productUnavailable
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled:
                break
            case .pending:
                errorMessage = AppCopy.Premium.purchasePending
            @unknown default:
                break
            }
        } catch {
            errorMessage = AppCopy.Premium.purchaseFailed
        }
    }

    func restore() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isPremium {
                errorMessage = AppCopy.Premium.restoreEmpty
            }
        } catch {
            errorMessage = AppCopy.Premium.restoreFailed
        }
    }

    private func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == PremiumLimits.productID {
                unlocked = true
                break
            }
        }
        applyPremium(unlocked)
    }

    private func listenForTransactions() {
        Task {
            for await result in Transaction.updates {
                guard let transaction = try? checkVerified(result) else { continue }
                if transaction.productID == PremiumLimits.productID {
                    await refreshEntitlements()
                }
                await transaction.finish()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    #if DEBUG
    func syncFromStorage() {
        isPremium = PremiumStorage.isPremium
    }
    #endif

    private func applyPremium(_ unlocked: Bool) {
        isPremium = unlocked
        PremiumStorage.setPremium(unlocked)
    }

    private enum StoreError: Error {
        case failedVerification
    }
}
