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

    /// The Pro product did not come back from the App Store. Distinct from
    /// `lastError`: this is a quiet state, not something to shout about.
    private(set) var productUnavailable = false

    init() {
        Task { await listenForTransactions() }
        Task { await refresh() }
    }

    /// Reloads the Pro product and entitlement state.
    /// Returns `true` only when a purchasable product came back from the App Store.
    /// On failure `lastError` is left set so callers can surface it.
    /// - Parameter surfacingErrors: `true` only when the person asked for this
    ///   (tapped Buy or Restore). A background load on opening the paywall sets
    ///   `productUnavailable` instead, so a red error does not greet someone who
    ///   merely opened the screen while offline.
    @discardableResult
    func refresh(surfacingErrors: Bool = true) async -> Bool {
        isLoading = true
        if surfacingErrors { lastError = nil }
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: [Self.proProductID])
            product = products.first
            productUnavailable = product == nil
            await updateEntitlements()

            if product == nil {
                // `Product.products(for:)` does NOT throw for an unknown or
                // not-yet-purchasable identifier — it returns an empty array.
                if surfacingErrors { lastError = Self.unavailableMessage }
                return false
            }
            return true
        } catch {
            product = nil
            productUnavailable = true
            if surfacingErrors {
                lastError = "Could not reach the App Store: \(error.localizedDescription)"
            }
            return false
        }
    }

    static var unavailableMessage: String {
        var message = "AussieStart Pro isn't available from the App Store on this account yet. "
        message += "Try again shortly, or tap Restore if you have already bought it."
        #if DEBUG || ALLOW_STORE_DIAGNOSTICS
        message += "\n\nDiagnostic: the App Store returned no product for "
        message += "\(Self.proProductID). Payments allowed: \(AppStore.canMakePayments). "
        message += "In the simulator this usually means the scheme's StoreKit "
        message += "configuration is not active — check Debug > StoreKit > Manage "
        message += "Transactions is enabled, and erase the simulator if it is."
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
