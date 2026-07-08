import SwiftUI

struct RootView: View {
    @AppStorage("appLanguage") private var lang = "zh"
    @EnvironmentObject private var incense: IncenseStore
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
            // Resume meditation music if incense is still burning (app relaunch).
            if incense.isBurning {
                IncenseMusicPlayer.shared.startIfNeeded(remaining: incense.remaining())
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Ambient audio pauses when the app is backgrounded; resume on
            // return if the incense is still burning.
            if phase == .active, incense.isBurning {
                IncenseMusicPlayer.shared.startIfNeeded(remaining: incense.remaining())
            }
        }
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
