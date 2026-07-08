import Foundation

/// 上香: one stick of incense burns in (near) real time, persisting across
/// app launches. Completion while away is detected on next launch.
final class IncenseStore: ObservableObject {
    static let cost = 10
    #if DEBUG
    static let duration: TimeInterval = 60            // debug: 1 minute
    #else
    static let duration: TimeInterval = 30 * 60       // 一炷香 ≈ 30 分钟
    #endif

    @Published private(set) var burningStart: Date?
    @Published private(set) var totalCount: Int
    /// The incense finished while the app was closed — surface it once.
    @Published var pendingCompletion = false

    private let startKey = "incenseStart"
    private let countKey = "incenseCount"

    init() {
        totalCount = UserDefaults.standard.integer(forKey: countKey)
        let ts = UserDefaults.standard.double(forKey: startKey)
        if ts > 0 {
            let start = Date(timeIntervalSince1970: ts)
            if Date() >= start.addingTimeInterval(Self.duration) {
                UserDefaults.standard.removeObject(forKey: startKey)
                totalCount += 1
                UserDefaults.standard.set(totalCount, forKey: countKey)
                pendingCompletion = true
            } else {
                burningStart = start
            }
        }
    }

    var isBurning: Bool { burningStart != nil }
    var endDate: Date? { burningStart?.addingTimeInterval(Self.duration) }

    func remaining(at date: Date = Date()) -> TimeInterval {
        guard let end = endDate else { return 0 }
        return max(0, end.timeIntervalSince(date))
    }

    /// 0 = just lit, 1 = burned out.
    func progress(at date: Date = Date()) -> Double {
        guard let start = burningStart else { return 0 }
        return min(1, date.timeIntervalSince(start) / Self.duration)
    }

    func light() {
        let now = Date()
        burningStart = now
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: startKey)
    }

    func finish() {
        burningStart = nil
        UserDefaults.standard.removeObject(forKey: startKey)
        totalCount += 1
        UserDefaults.standard.set(totalCount, forKey: countKey)
    }
}
