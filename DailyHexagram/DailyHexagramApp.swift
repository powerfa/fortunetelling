import SwiftUI

@main
struct DailyHexagramApp: App {
    @StateObject private var store = DailyStore()
    @StateObject private var coins = CoinStore()
    @StateObject private var storeKit = StoreManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(coins)
                .environmentObject(storeKit)
        }
    }
}
