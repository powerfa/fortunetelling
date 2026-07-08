import SwiftUI

@main
struct DailyHexagramApp: App {
    @StateObject private var store = DailyStore()
    @StateObject private var coins = CoinStore()
    @StateObject private var storeKit = StoreManager()
    @StateObject private var blessing = BlessingStore()
    @StateObject private var incense = IncenseStore()

    init() {
        // Warm the 64-hexagram store (~320 KB JSON decode) off the main thread
        // so the first result render doesn't pay for it.
        DispatchQueue.global(qos: .utility).async {
            _ = HexagramStore.shared
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(coins)
                .environmentObject(storeKit)
                .environmentObject(blessing)
                .environmentObject(incense)
        }
    }
}
