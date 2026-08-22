import StoreKit
import StoreKitTest
import XCTest

final class StoreKitIAPTests: XCTestCase {
    private static let productID = "com.aussiestart.app.pro"
    private var session: SKTestSession!

    override func setUp() async throws {
        continueAfterFailure = false
        let url = try XCTUnwrap(
            Bundle(for: StoreKitIAPTests.self).url(forResource: "Products", withExtension: "storekit"),
            "Products.storekit must be in the AussieStartTests bundle"
        )
        session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
    }

    override func tearDown() async throws {
        session?.clearTransactions()
        session = nil
    }

    func testProProductLoadsFromStoreKitConfig() async throws {
        let products = try await Product.products(for: [Self.productID])
        XCTAssertEqual(products.count, 1, "Local StoreKit config should return AussieStart Pro")
        let product = try XCTUnwrap(products.first)
        XCTAssertEqual(product.id, Self.productID)
        XCTAssertEqual(product.type, .nonConsumable)
        XCTAssertFalse(product.isFamilyShareable)
        XCTAssertFalse(product.displayPrice.isEmpty)
    }

    func testPurchaseGrantsProEntitlement() async throws {
        let products = try await Product.products(for: [Self.productID])
        let product = try XCTUnwrap(products.first)

        let result = try await product.purchase()
        guard case .success(let verification) = result else {
            XCTFail("Expected a successful purchase, got \(String(describing: result))")
            return
        }
        let transaction = try verification.payloadValue
        XCTAssertEqual(transaction.productID, Self.productID)
        await transaction.finish()

        let entitled = await hasProEntitlement()
        XCTAssertTrue(entitled, "Pro entitlement missing after purchase")
    }

    func testRestoreFindsExistingPurchase() async throws {
        let products = try await Product.products(for: [Self.productID])
        let product = try XCTUnwrap(products.first)
        let result = try await product.purchase()
        guard case .success(let verification) = result else {
            XCTFail("Expected a successful purchase before restore, got \(String(describing: result))")
            return
        }
        let transaction = try verification.payloadValue
        await transaction.finish()
        try await AppStore.sync()
        let entitled = await hasProEntitlement()
        XCTAssertTrue(entitled, "Restore/sync should surface the existing Pro purchase")
    }

    private func hasProEntitlement() async -> Bool {
        for await item in Transaction.currentEntitlements {
            if case .verified(let transaction) = item,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                return true
            }
        }
        return false
    }
}
