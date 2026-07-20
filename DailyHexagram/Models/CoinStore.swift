import Foundation

/// 福币 wallet: earned by daily check-in / invites or purchased; spent on
/// recasts, incense and charms.
///
/// Storage: iCloud key-value store (NSUbiquitousKeyValueStore) — the wallet
/// follows the user's Apple ID, so it survives reinstalls and stays in sync
/// across their devices. UserDefaults keeps a local mirror as an offline /
/// signed-out fallback. Check-in history is a set of "yyyy-MM-dd" strings.
final class CoinStore: ObservableObject {
    static let recastCost = 10
    static let baseReward = 1        // 普通用户每日签到
    static let premiumReward = 2     // 会员每日签到

    @Published private(set) var balance: Int
    @Published private(set) var checkInDates: Set<String>

    private let balanceKey = "coinBalance"
    private let datesKey = "checkInDates"
    private let migratedKey = "coinsCloudMigrated"

    private let kv = NSUbiquitousKeyValueStore.default
    private var observer: NSObjectProtocol?

    init() {
        // Local (pre-iCloud) state, including the very old single-date key.
        let defaults = UserDefaults.standard
        let localBalance = defaults.integer(forKey: balanceKey)
        var localDates = Set(defaults.stringArray(forKey: datesKey) ?? [])
        if let legacy = defaults.string(forKey: "lastCheckInDate") {
            localDates.insert(legacy)
            defaults.removeObject(forKey: "lastCheckInDate")
        }

        kv.synchronize()
        let cloudBalance: Int? = kv.object(forKey: balanceKey) != nil
            ? Int(kv.longLong(forKey: balanceKey)) : nil
        let cloudDates = Set(kv.array(forKey: datesKey) as? [String] ?? [])

        if let cloudBalance, defaults.bool(forKey: migratedKey) {
            // Cloud is the source of truth once this install has migrated.
            balance = cloudBalance
        } else {
            // First launch of this install (fresh reinstall, or upgrade from a
            // local-only version): one-time merge, richer state wins.
            balance = max(localBalance, cloudBalance ?? 0)
            defaults.set(true, forKey: migratedKey)
        }
        checkInDates = localDates.union(cloudDates)
        persist()

        // Another device changed the wallet while we're running.
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kv,
            queue: .main
        ) { [weak self] _ in
            self?.adoptRemote()
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    var canCheckInToday: Bool {
        !checkInDates.contains(DailyStore.todayString)
    }

    func checkIn(isPremium: Bool) {
        guard canCheckInToday else { return }
        checkInDates.insert(DailyStore.todayString)
        balance += isPremium ? Self.premiumReward : Self.baseReward
        persist()
    }

    func add(_ amount: Int) {
        balance += amount
        persist()
    }

    @discardableResult
    func spend(_ amount: Int) -> Bool {
        guard balance >= amount else { return false }
        balance -= amount
        persist()
        return true
    }

    // MARK: - Sync plumbing

    private func adoptRemote() {
        if kv.object(forKey: balanceKey) != nil {
            balance = Int(kv.longLong(forKey: balanceKey))
        }
        if let arr = kv.array(forKey: datesKey) as? [String] {
            checkInDates.formUnion(arr)
        }
        let defaults = UserDefaults.standard
        defaults.set(balance, forKey: balanceKey)
        defaults.set(Array(checkInDates), forKey: datesKey)
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(balance, forKey: balanceKey)
        defaults.set(Array(checkInDates), forKey: datesKey)
        kv.set(Int64(balance), forKey: balanceKey)
        kv.set(Array(checkInDates), forKey: datesKey)
        kv.synchronize()
    }
}
