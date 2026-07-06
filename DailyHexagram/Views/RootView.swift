import SwiftUI

struct RootView: View {
    @AppStorage("appLanguage") private var lang = "zh"

    var body: some View {
        TabView {
            TodayTab()
                .tabItem {
                    Label(L10n.t("tab_today", lang), systemImage: "sun.max.fill")
                }
            HistoryView()
                .tabItem {
                    Label(L10n.t("tab_history", lang), systemImage: "clock.arrow.circlepath")
                }
            GuideView()
                .tabItem {
                    Label(L10n.t("tab_guide", lang), systemImage: "book.closed.fill")
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
                        HStack(spacing: 4) {
                            Image(systemName: "circle.circle.fill")
                                .foregroundStyle(.yellow)
                            Text("\(coins.balance)")
                                .font(.subheadline.bold())
                        }
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
        }
    }
}

#Preview {
    RootView()
        .environmentObject(DailyStore())
        .environmentObject(CoinStore())
        .environmentObject(StoreManager())
}
