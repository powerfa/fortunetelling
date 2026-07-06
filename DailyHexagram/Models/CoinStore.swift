import Foundation

/// 福币 wallet: earned by daily check-in or purchased; spent on recasts.
final class CoinStore: ObservableObject {
    static let checkInReward = 2
    static let recastCost = 10

    @Published private(set) var balance: Int
    @Published private(set) var lastCheckIn: String

    private let balanceKey = "coinBalance"
    private let checkInKey = "lastCheckInDate"

    init() {
        balance = UserDefaults.standard.integer(forKey: balanceKey)
        lastCheckIn = UserDefaults.standard.string(forKey: checkInKey) ?? ""
    }

    var canCheckInToday: Bool {
        lastCheckIn != DailyStore.todayString
    }

    func checkIn() {
        guard canCheckInToday else { return }
        lastCheckIn = DailyStore.todayString
        UserDefaults.standard.set(lastCheckIn, forKey: checkInKey)
        add(Self.checkInReward)
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
