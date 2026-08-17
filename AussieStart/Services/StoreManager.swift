import Foundation
import StoreKit

@MainActor
@Observable
final class StoreManager {
    static let proProductID = "com.aussiestart.app.pro"

    private(set) var product: Product?
    private(set) var isPro = false
    private(set) var isLoading = false
    private(set) var lastError: String?

    init() {
        Task { await listenForTransactions() }
        Task { await refresh() }
    }

    func refresh() async {
        isLoading = true
        lastError = nil
        do {
            let products = try await Product.products(for: [Self.proProductID])
            product = products.first
            await updateEntitlements()
        } catch {
            lastError = error.localizedDescription
        }
        isLoading = false
    }

    func purchase() async {
        guard let product else {
            lastError = "Pro is unavailable right now. Try Restore, or try again later."
            await refresh()
            return
        }

        isLoading = true
        lastError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateEntitlements()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
        isLoading = false
    }

    func restore() async {
        isLoading = true
        lastError = nil
        do {
            try await AppStore.sync()
            await updateEntitlements()
            if !isPro {
                lastError = "No previous Pro purchase was found for this Apple ID."
            }
        } catch {
            lastError = error.localizedDescription
        }
        isLoading = false
    }

    func canRead(_ article: ArticleMeta) -> Bool {
        !article.requiresPro || isPro
    }

    var displayPrice: String {
        product?.displayPrice ?? "$9.99"
    }

    private func updateEntitlements() async {
        var unlocked = false
        for await entitlement in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(entitlement),
               transaction.productID == Self.proProductID,
               transaction.revocationDate == nil {
                unlocked = true
                break
            }
        }
        isPro = unlocked
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.unverified
        case .verified(let value):
            return value
        }
    }

    private func listenForTransactions() async {
        for await update in Transaction.updates {
            if let transaction = try? checkVerified(update) {
                await transaction.finish()
                await updateEntitlements()
            }
        }
    }
}

enum StoreError: LocalizedError {
    case unverified

    var errorDescription: String? {
        "Could not verify this purchase with the App Store."
    }
}
