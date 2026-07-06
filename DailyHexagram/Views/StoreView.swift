import SwiftUI
import StoreKit

/// Coins & Premium: balance, daily check-in, subscription, coin packs.
struct StoreView: View {
    @EnvironmentObject private var coins: CoinStore
    @EnvironmentObject private var storeKit: StoreManager
    @AppStorage("appLanguage") private var lang = "zh"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Label {
                            Text(L10n.t("balance", lang))
                        } icon: {
                            Image(systemName: "circle.circle.fill")
                                .foregroundStyle(.yellow)
                        }
                        Spacer()
                        Text("\(coins.balance)")
                            .font(.title3.bold())
                            .foregroundStyle(Color.accentColor)
                    }
                    Button {
                        withAnimation { coins.checkIn() }
                    } label: {
                        Label(
                            coins.canCheckInToday ? L10n.t("check_in", lang) : L10n.t("checked_in", lang),
                            systemImage: coins.canCheckInToday ? "calendar.badge.plus" : "checkmark.circle.fill"
                        )
                    }
                    .disabled(!coins.canCheckInToday)
                }

                Section(L10n.t("premium_title", lang)) {
                    if storeKit.isPremium {
                        Label(L10n.t("premium_active", lang), systemImage: "crown.fill")
                            .foregroundStyle(.orange)
                    } else {
                        Text(L10n.t("premium_benefits", lang))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        if storeKit.subscriptions.isEmpty {
                            Text(L10n.t("store_unavailable", lang))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(storeKit.subscriptions) { product in
                                purchaseRow(product)
                            }
                        }
                    }
                }

                Section(L10n.t("coin_packs", lang)) {
                    if storeKit.coinPacks.isEmpty {
                        Text(L10n.t("store_unavailable", lang))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(storeKit.coinPacks) { product in
                            purchaseRow(product)
                        }
                    }
                }

                Section {
                    Button(L10n.t("restore", lang)) {
                        Task { await storeKit.restore() }
                    }
                    #if DEBUG
                    Button(L10n.t(storeKit.isPremium ? "debug_premium_off" : "debug_premium_on", lang)) {
                        storeKit.togglePremiumForTesting()
                    }
                    #endif
                }
            }
            .navigationTitle(L10n.t("store_title", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.t("done", lang)) { dismiss() }
                }
            }
        }
    }

    private func purchaseRow(_ product: Product) -> some View {
        Button {
            Task { await storeKit.purchase(product, coins: coins) }
        } label: {
            HStack {
                Text(localizedName(product))
                Spacer()
                Text(product.displayPrice)
                    .bold()
                    .foregroundStyle(Color.accentColor)
            }
        }
        .disabled(storeKit.purchaseInFlight)
    }

    /// Product names follow the app language instead of StoreKit's bilingual displayName.
    private func localizedName(_ product: Product) -> String {
        let key: String?
        switch product.id {
        case StoreManager.ProductID.monthly:  key = "prod_monthly"
        case StoreManager.ProductID.yearly:   key = "prod_yearly"
        case StoreManager.ProductID.coins60:  key = "prod_coins60"
        case StoreManager.ProductID.coins200: key = "prod_coins200"
        case StoreManager.ProductID.coins600: key = "prod_coins600"
        default: key = nil
        }
        if let key {
            return L10n.t(key, lang)
        }
        return product.displayName.isEmpty ? product.id : product.displayName
    }
}

#Preview {
    StoreView()
        .environmentObject(CoinStore())
        .environmentObject(StoreManager())
}
