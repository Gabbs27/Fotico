import StoreKit
import SwiftUI

@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published var products: [Product] = []
    #if DEBUG
    @Published var isPro = true  // All tiers unlocked for testing
    #else
    @Published var isPro = false
    #endif

    private let productIDs = ["com.lume.pro.monthly", "com.lume.pro.annual"]

    func loadProducts() async {
        do {
            products = try await Product.products(for: Set(productIDs))
                .sorted { $0.price < $1.price }
        } catch {
            print("[Subscription] Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            isPro = true
            return true
        case .pending, .userCancelled:
            return false
        @unknown default:
            return false
        }
    }

    func checkSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if productIDs.contains(transaction.productID) {
                    isPro = true
                    return
                }
            }
        }
        isPro = false
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await checkSubscriptionStatus()
    }

    func listenForUpdates() {
        Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await checkSubscriptionStatus()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw SubscriptionError.unverified
        case .verified(let safe): return safe
        }
    }
}

enum SubscriptionError: Error {
    case unverified
}
