import Foundation
import StoreKit

/// Manages StoreKit 2 in-app purchases for PillPal Premium.
@MainActor
final class StoreManager: ObservableObject {

    static let premiumProductID = "com.chadnewbry.pillpal.premium"

    @Published private(set) var premiumProduct: Product?
    @Published private(set) var isPremium: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var purchaseError: String?

    private var transactionListener: Task<Void, Error>?

    init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await refreshPurchaseStatus() }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.premiumProductID])
            premiumProduct = products.first
        } catch {
            print("StoreManager: Failed to load products: \(error)")
        }
    }

    func purchase() async {
        guard let product = premiumProduct else {
            purchaseError = "Product not available. Please try again later."
            return
        }

        isLoading = true
        purchaseError = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                isPremium = true
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Purchase is pending approval."
            @unknown default:
                purchaseError = "An unexpected error occurred."
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true
        purchaseError = nil

        try? await AppStore.sync()
        await refreshPurchaseStatus()

        if !isPremium {
            purchaseError = "No previous purchase found."
        }

        isLoading = false
    }

    func refreshPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.premiumProductID,
               transaction.revocationDate == nil {
                isPremium = true
                return
            }
        }
        isPremium = false
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshPurchaseStatus()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
