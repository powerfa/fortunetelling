import Foundation
import StoreKit

/// StoreKit 2: premium subscription (detailed readings) + consumable coin packs.
@MainActor
final class StoreManager: ObservableObject {
    enum ProductID {
        static let monthly  = "com.dj.DailyHexagram.premium.monthly"
        static let yearly   = "com.dj.DailyHexagram.premium.yearly"
        static let coins60  = "com.dj.DailyHexagram.coins60"
        static let coins200 = "com.dj.DailyHexagram.coins200"
        static let coins600 = "com.dj.DailyHexagram.coins600"
        static let all = [monthly, yearly, coins60, coins200, coins600]
        static let coinAmounts: [String: Int] = [coins60: 60, coins200: 200, coins600: 600]
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPremium = false
    @Published private(set) var purchaseInFlight = false

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
            if case .success(.verified(let transaction)) = result {
                if let amount = ProductID.coinAmounts[transaction.productID] {
                    coins.add(amount)
                }
                await transaction.finish()
                await refreshPremium()
            }
        } catch {
            // Purchase cancelled or failed; nothing to do.
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
