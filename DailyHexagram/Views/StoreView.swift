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
                            Image("CoinIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                        }
                        Spacer()
                        Text("\(coins.balance)")
                            .font(.title3.bold())
                            .foregroundStyle(Color.accentColor)
                    }
                    Button {
                        withAnimation { coins.checkIn(isPremium: storeKit.isPremium) }
                    } label: {
                        Label(
                            checkInLabel,
                            systemImage: coins.canCheckInToday ? "calendar.badge.plus" : "checkmark.circle.fill"
                        )
                    }
                    .disabled(!coins.canCheckInToday)

                    CheckInCalendarView(checkedDates: coins.checkInDates)
                        .padding(.vertical, 6)
                } footer: {
                    Text(L10n.t("checkin_rule", lang))
                }

                Section {
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
                } header: {
                    Text(L10n.t("premium_title", lang))
                } footer: {
                    if !storeKit.isPremium {
                        Text(L10n.t("sub_note", lang))
                    }
                }

                Section(L10n.t("coin_packs", lang)) {
                    if storeKit.coinPacks.isEmpty {
                        Text(L10n.t("store_unavailable", lang))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(storeKit.coinPacks) { product in
                            coinPackRow(product)
                        }
                    }
                }

                Section {
                    Button(L10n.t("restore", lang)) {
                        Task { await storeKit.restore() }
                    }
                    Link(L10n.t("terms_of_use", lang), destination: LegalLinks.termsOfUse)
                    Link(L10n.t("privacy_policy", lang), destination: LegalLinks.privacyPolicy)
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
            .alert(
                L10n.t("purchase_failed_title", lang),
                isPresented: Binding(
                    get: { storeKit.purchaseError != nil },
                    set: { if !$0 { storeKit.purchaseError = nil } }
                )
            ) {
                Button(L10n.t("ok", lang), role: .cancel) { storeKit.purchaseError = nil }
            } message: {
                Text(storeKit.purchaseError ?? "")
            }
            .alert(L10n.t("purchase_pending_title", lang), isPresented: $storeKit.purchasePending) {
                Button(L10n.t("ok", lang), role: .cancel) {}
            } message: {
                Text(L10n.t("purchase_pending_msg", lang))
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

    private var checkInLabel: String {
        guard coins.canCheckInToday else { return L10n.t("checked_in", lang) }
        let reward = storeKit.isPremium ? CoinStore.premiumReward : CoinStore.baseReward
        return "\(L10n.t("check_in", lang)) +\(reward)"
    }

    /// Coin pack row: name + savings badge (computed from real unit prices) + price.
    private func coinPackRow(_ product: Product) -> some View {
        Button {
            Task { await storeKit.purchase(product, coins: coins) }
        } label: {
            HStack(spacing: 8) {
                Text(localizedName(product))
                if let pct = savingsPercent(product), pct > 0 {
                    badge(String(format: L10n.t("save_pct", lang), pct), color: .red)
                }
                if product.id == StoreManager.ProductID.coins2500 {
                    badge(L10n.t("best_value", lang), color: .orange)
                }
                Spacer()
                Text(product.displayPrice)
                    .bold()
                    .foregroundStyle(Color.accentColor)
            }
        }
        .disabled(storeKit.purchaseInFlight)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.14)))
            .foregroundStyle(color)
    }

    /// Percent saved vs. the smallest pack's per-coin price, from live StoreKit prices.
    private func savingsPercent(_ product: Product) -> Int? {
        guard let amount = StoreManager.ProductID.coinAmounts[product.id],
              let base = storeKit.coinPacks.first,
              base.id != product.id,
              let baseAmount = StoreManager.ProductID.coinAmounts[base.id],
              amount > 0, baseAmount > 0
        else { return nil }
        let unit = NSDecimalNumber(decimal: product.price).doubleValue / Double(amount)
        let baseUnit = NSDecimalNumber(decimal: base.price).doubleValue / Double(baseAmount)
        guard baseUnit > 0 else { return nil }
        return Int(((1 - unit / baseUnit) * 100).rounded())
    }

    /// Product names follow the app language instead of StoreKit's bilingual displayName.
    private func localizedName(_ product: Product) -> String {
        let key: String?
        switch product.id {
        case StoreManager.ProductID.monthly:   key = "prod_monthly"
        case StoreManager.ProductID.yearly:    key = "prod_yearly"
        case StoreManager.ProductID.coins30:   key = "prod_coins30"
        case StoreManager.ProductID.coins180:  key = "prod_coins180"
        case StoreManager.ProductID.coins800:  key = "prod_coins800"
        case StoreManager.ProductID.coins2500: key = "prod_coins2500"
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
