import SwiftUI

struct RootView: View {
    @AppStorage("appLanguage") private var lang = "zh"
    @AppStorage("onboardingSeen") private var onboardingSeen = false
    @EnvironmentObject private var incense: IncenseStore
    @EnvironmentObject private var store: DailyStore
    @EnvironmentObject private var coins: CoinStore
    @EnvironmentObject private var storeKit: StoreManager
    @EnvironmentObject private var blessing: BlessingStore
    @EnvironmentObject private var invite: InviteManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            TodayTab()
                .tabItem {
                    Label(L10n.t("tab_today", lang), systemImage: "circle.grid.cross.fill")
                }
            BlessingView()
                .tabItem {
                    Label(L10n.t("tab_blessing", lang), systemImage: "sparkles")
                }
            IncenseView()
                .tabItem {
                    Label(L10n.t("tab_incense", lang), systemImage: "flame.fill")
                }
            HistoryView()
                .tabItem {
                    Label(L10n.t("tab_history", lang), systemImage: "clock.arrow.circlepath")
                }
        }
        .onAppear {
            // Coins bought via Ask to Buy / interrupted purchases arrive
            // through Transaction.updates — route them into the wallet.
            storeKit.externalCoinGrant = { [weak coins] amount in
                coins?.add(amount)
            }
            // Resume meditation music if incense is still burning (app relaunch).
            if incense.isBurning {
                IncenseMusicPlayer.shared.startIfNeeded(remaining: incense.remaining())
            }
            // Credit any invite rewards that arrived while we were away.
            Task { await invite.collectRewards(coins: coins) }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            // The app may have crossed midnight while suspended.
            store.refreshForNewDay()
            blessing.load()
            // Ambient audio pauses when the app is backgrounded; resume on
            // return if the incense is still burning.
            if incense.isBurning {
                IncenseMusicPlayer.shared.startIfNeeded(remaining: incense.remaining())
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { !onboardingSeen },
            set: { if !$0 { onboardingSeen = true } }
        )) {
            OnboardingView()
        }
        .alert(
            inviteRewardText,
            isPresented: Binding(
                get: { invite.message?.key == "invite_reward_arrived" },
                set: { if !$0 { invite.message = nil } }
            )
        ) {
            Button(L10n.t("ok", lang), role: .cancel) { invite.message = nil }
        }
    }

    private var inviteRewardText: String {
        guard let m = invite.message, m.key == "invite_reward_arrived" else { return "" }
        return String(format: L10n.t(m.key, lang), m.amount)
    }
}

struct TodayTab: View {
    @EnvironmentObject private var store: DailyStore
    @EnvironmentObject private var coins: CoinStore
    @AppStorage("appLanguage") private var lang = "zh"
    @State private var showSettings = false
    @State private var showStore = false
    @State private var showGuide = false

    var body: some View {
        NavigationStack {
            Group {
                if let result = store.todayResult {
                    ResultView(result: result)
                } else {
                    CastView()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L10n.t("app_title", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showStore = true
                    } label: {
                        HStack(spacing: 5) {
                            Image("CoinIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                            Text("\(coins.balance)")
                                .font(.subheadline.bold())
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showGuide = true
                    } label: {
                        Image(systemName: "book.closed")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showStore) {
                StoreView()
            }
            .sheet(isPresented: $showGuide) {
                GuideView()
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(DailyStore())
        .environmentObject(CoinStore())
        .environmentObject(StoreManager())
        .environmentObject(IncenseStore())
}
