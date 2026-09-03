import Foundation
import StoreKit
import OSLog

@MainActor
@Observable
final class StoreManager {
    static let proProductID = "com.aussiestart.app.pro"

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.aussiestart.app",
        category: "StoreKit"
    )

    /// Emits to both the unified log (Console.app, filter subsystem
    /// `com.aussiestart.app`) and stdout, so it shows in the Xcode console
    /// whether the app is attached to the debugger or not.
    private static func trace(_ message: String) {
        StoreLog.event(message)
    }

    private(set) var product: Product?
    private(set) var isPro = false
    private(set) var isLoading = false
    private(set) var lastError: String?

    /// The Pro product did not come back from the App Store. Distinct from
    /// `lastError`: this is a quiet state, not something to shout about.
    private(set) var productUnavailable = false

    /// A readable trace of the last store lookup — what was asked for, what
    /// came back, and from which storefront. Shown on the paywall in Debug
    /// builds so a device can be diagnosed without being tethered to Xcode.
    private(set) var diagnostics = "No store lookup yet."

    init() {
        StoreLog.launchBanner()
        Self.trace("StoreManager init — starting transaction listener and first lookup")
        Task { await listenForTransactions() }
        Task { await refresh(surfacingErrors: false) }
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

        let started = Date.now
        let bundleID = Bundle.main.bundleIdentifier ?? "nil"
        let canPay = AppStore.canMakePayments
        let storefront = await Storefront.current
        let front = storefront.map { "\($0.countryCode) (id \($0.id))" } ?? "nil — not reachable"

        // The bundle identifier is the single most common cause of an empty
        // result on a device: it must match the App Store Connect record
        // exactly, and free provisioning quietly rewrites it.
        Self.trace("lookup start · bundle=\(bundleID) · asking for=\(Self.proProductID) · storefront=\(front) · canMakePayments=\(canPay)")

        do {
            let products = try await Product.products(for: [Self.proProductID])
            let elapsed = String(format: "%.2fs", Date.now.timeIntervalSince(started))
            product = products.first
            productUnavailable = product == nil
            await updateEntitlements()

            let returned = products.isEmpty ? "none" : products.map(\.id).joined(separator: ", ")
            Self.trace("lookup done in \(elapsed) · returned \(products.count) product(s): \(returned)")
            for item in products {
                Self.trace("  · \(item.id) — \(item.displayName) — \(item.displayPrice) — \(item.type)")
            }

            diagnostics = """
            bundle: \(bundleID)
            asked for: \(Self.proProductID)
            storefront: \(front)
            canMakePayments: \(canPay)
            returned: \(products.count) — \(returned)
            entitled: \(isPro)
            took: \(elapsed)
            """

            if product == nil {
                // `Product.products(for:)` does NOT throw for an unknown or
                // not-yet-purchasable identifier — it returns an empty array.
                Self.trace("EMPTY RESULT. The id is unknown to this storefront, or the product is not yet purchasable. Check: bundle id matches App Store Connect; the IAP is Ready to Submit or Approved; the Paid Apps agreement is Active; and allow a few hours after any of those changed.")
                if surfacingErrors { lastError = Self.unavailableMessage }
                return false
            }
            return true
        } catch {
            product = nil
            productUnavailable = true
            // localizedDescription throws away the useful part of a StoreKitError.
            Self.trace("LOOKUP THREW: \(String(describing: error))")
            diagnostics = """
            bundle: \(bundleID)
            asked for: \(Self.proProductID)
            storefront: \(front)
            canMakePayments: \(canPay)
            error: \(String(describing: error))
            """
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
        Self.trace(">>> purchase() ENTERED · product currently \(product == nil ? "nil" : "loaded") · isPro=\(isPro) · isLoading=\(isLoading)")

        // Re-check once in case the first load raced the App Store.
        // `refresh()` sets `lastError` itself, so don't clobber it here.
        if product == nil {
            Self.trace("purchase() has no product — re-running the lookup first")
            guard await refresh() else {
                Self.trace("<<< purchase() ABORTED · the lookup returned no product, so there is nothing to buy")
                return
            }
        }
        guard let product else {
            Self.trace("<<< purchase() ABORTED · product still nil after the lookup")
            lastError = Self.unavailableMessage
            return
        }

        isLoading = true
        lastError = nil
        do {
            Self.trace("purchase starting for \(product.id) at \(product.displayPrice)")
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                Self.trace("purchase SUCCESS · transaction \(transaction.id) for \(transaction.productID)")
                await transaction.finish()
                await updateEntitlements()
            case .userCancelled:
                Self.trace("purchase cancelled by the person")
            case .pending:
                Self.trace("purchase PENDING — awaiting approval (Ask to Buy, or SCA)")
            @unknown default:
                Self.trace("purchase returned an unknown result")
            }
        } catch {
            Self.trace("purchase THREW: \(String(describing: error))")
            lastError = error.localizedDescription
        }
        isLoading = false
        Self.trace("<<< purchase() FINISHED · isPro=\(isPro)")
    }

    func restore() async {
        Self.trace(">>> restore() ENTERED — this will ask for an Apple ID password")
        isLoading = true
        lastError = nil
        do {
            try await AppStore.sync()
            await updateEntitlements()
            Self.trace("restore() sync complete · isPro=\(isPro)")
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
        if isPro != unlocked {
            Self.trace("entitlement changed: isPro=\(unlocked)")
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
