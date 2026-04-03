import StoreKit
import SwiftUI

@MainActor
@Observable class SubscriptionService {
    static let shared = SubscriptionService()

    var products: [Product] = []
    #if DEBUG
    var isPro = true  // All tiers unlocked for testing
    #else
    var isPro = false
    #endif

    private let productIDs = ["com.lume.pro.monthly", "com.lume.pro.annual"]
    private var updateListenerTask: Task<Void, Never>?

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
        // Cancel previous listener to prevent accumulation
        updateListenerTask?.cancel()
        updateListenerTask = Task {
            for await result in Transaction.updates {
                guard !Task.isCancelled else { break }
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
