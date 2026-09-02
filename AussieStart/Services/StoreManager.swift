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

    /// Reloads the Pro product and entitlement state.
    /// Returns `true` only when a purchasable product came back from the App Store.
    /// On failure `lastError` is left set so callers can surface it.
    @discardableResult
    func refresh() async -> Bool {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: [Self.proProductID])
            product = products.first
            await updateEntitlements()

            if product == nil {
                // `Product.products(for:)` does NOT throw for an unknown or
                // not-yet-purchasable identifier — it returns an empty array.
                lastError = Self.unavailableMessage
                return false
            }
            return true
        } catch {
            product = nil
            lastError = "Could not reach the App Store: \(error.localizedDescription)"
            return false
        }
    }

    static var unavailableMessage: String {
        var message = "AussieStart Pro isn't available from the App Store on this account yet. "
        message += "Try again shortly, or tap Restore if you have already bought it."
        #if DEBUG || ALLOW_STORE_DIAGNOSTICS
        message += "\n(No product returned for \(Self.proProductID).)"
        #endif
        return message
    }

    func purchase() async {
        // Re-check once in case the first load raced the App Store.
        // `refresh()` sets `lastError` itself, so don't clobber it here.
        if product == nil {
            guard await refresh() else { return }
        }
        guard let product else {
            lastError = Self.unavailableMessage
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
