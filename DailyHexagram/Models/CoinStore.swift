import Foundation

/// 福币 wallet: earned by daily check-in or purchased; spent on recasts.
/// Check-in history is kept as a set of "yyyy-MM-dd" strings for the calendar view.
final class CoinStore: ObservableObject {
    static let recastCost = 10
    static let baseReward = 1        // 普通用户每日签到
    static let premiumReward = 2     // 会员每日签到

    @Published private(set) var balance: Int
    @Published private(set) var checkInDates: Set<String>

    private let balanceKey = "coinBalance"
    private let datesKey = "checkInDates"

    init() {
        balance = UserDefaults.standard.integer(forKey: balanceKey)
        var dates = Set(UserDefaults.standard.stringArray(forKey: datesKey) ?? [])
        // Migrate from the old single-date key.
        if let legacy = UserDefaults.standard.string(forKey: "lastCheckInDate") {
            dates.insert(legacy)
            UserDefaults.standard.removeObject(forKey: "lastCheckInDate")
            UserDefaults.standard.set(Array(dates), forKey: datesKey)
        }
        checkInDates = dates
    }

    var canCheckInToday: Bool {
        !checkInDates.contains(DailyStore.todayString)
    }

    func checkIn(isPremium: Bool) {
        guard canCheckInToday else { return }
        checkInDates.insert(DailyStore.todayString)
        UserDefaults.standard.set(Array(checkInDates), forKey: datesKey)
        add(isPremium ? Self.premiumReward : Self.baseReward)
    }

    func add(_ amount: Int) {
        balance += amount
        UserDefaults.standard.set(balance, forKey: balanceKey)
    }

    @discardableResult
    func spend(_ amount: Int) -> Bool {
        guard balance >= amount else { return false }
        balance -= amount
        UserDefaults.standard.set(balance, forKey: balanceKey)
        return true
    }
}
