import Foundation
import StoreKit

/// StoreKit 2: premium subscription (detailed readings) + consumable coin packs.
@MainActor
final class StoreManager: ObservableObject {
    enum ProductID {
        static let monthly   = "com.dj.DailyHexagram.premium.monthly"
        static let yearly    = "com.dj.DailyHexagram.premium.yearly"
        static let coins30   = "com.dj.DailyHexagram.coins30"
        static let coins180  = "com.dj.DailyHexagram.coins180"
        static let coins800  = "com.dj.DailyHexagram.coins800"
        static let coins2500 = "com.dj.DailyHexagram.coins2500"
        static let all = [monthly, yearly, coins30, coins180, coins800, coins2500]
        static let coinAmounts: [String: Int] = [coins30: 30, coins180: 180, coins800: 800, coins2500: 2500]
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPremium = false
    @Published private(set) var purchaseInFlight = false
    /// Ask to Buy / deferred purchase is awaiting approval.
    @Published var purchasePending = false
    /// Human-readable failure to surface in an alert (nil = no error).
    @Published var purchaseError: String?

    /// Grants coins for transactions that arrive outside `purchase()` —
    /// e.g. an Ask to Buy approved later, or an interrupted purchase.
    /// Wired up by the root view to `CoinStore.add`.
    var externalCoinGrant: ((Int) -> Void)?

    var subscriptions: [Product] {
        products.filter { $0.type == .autoRenewable }.sorted { $0.price < $1.price }
    }
    var coinPacks: [Product] {
        products.filter { $0.type == .consumable }.sorted { $0.price < $1.price }
    }

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    // Consumables reaching us here (Ask to Buy approval,
                    // interrupted purchase) must still grant their coins.
                    if transaction.revocationDate == nil,
                       let amount = ProductID.coinAmounts[transaction.productID] {
                        self?.externalCoinGrant?(amount)
                    }
                    await transaction.finish()
                    await self?.refreshPremium()
                }
            }
        }
        Task {
            await loadProducts()
            await refreshPremium()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: ProductID.all)
        } catch {
            products = []
        }
    }

    func purchase(_ product: Product, coins: CoinStore) async {
        guard !purchaseInFlight else { return }
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(.verified(let transaction)):
                if let amount = ProductID.coinAmounts[transaction.productID] {
                    coins.add(amount)
                }
                await transaction.finish()
                await refreshPremium()
            case .success(.unverified):
                purchaseError = "Verification failed. Please try again or use Restore Purchases."
            case .pending:
                purchasePending = true
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch StoreKitError.userCancelled {
            // Not an error.
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshPremium()
    }

    func refreshPremium() async {
        var premium = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let t) = entitlement,
               t.productType == .autoRenewable,
               t.revocationDate == nil {
                premium = true
            }
        }
        isPremium = premium
        WidgetBridge.setPremium(premium)
    }

    #if DEBUG
    /// Simulator/local testing without App Store Connect.
    func togglePremiumForTesting() {
        isPremium.toggle()
        WidgetBridge.setPremium(isPremium)
    }
    #endif
}

/// Links required on the purchase screen (App Review). The privacy policy
/// must be a live page before submission — see README.
enum LegalLinks {
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyPolicy = URL(string: "https://dejunjiang316.github.io/daily-hexagram/privacy.html")!
}
