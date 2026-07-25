import Foundation
import SwiftUI

/// Persists today's divination and the reading history.
///
/// Storage: iCloud key-value store with a UserDefaults mirror (offline /
/// signed-out fallback). History merges across devices by date — the entry
/// with the newest `epoch` wins a same-day conflict. Today's result uses
/// last-writer-wins so a recast (which clears it) propagates correctly.
final class DailyStore: ObservableObject {
    @Published private(set) var todayResult: DivinationResult?
    /// 今日已重算次数（不设上限，价格阶梯递增）。
    @Published private(set) var recastCountToday = 0
    @Published private(set) var history: [DivinationResult] = []

    /// 重算不设次数上限，但价格阶梯递增以践行「再三渎，渎则不告」：
    /// 第1次 10，第2次 30，此后每次 ×10（300、3000、30000……）。
    static func recastCost(forCount count: Int) -> Int {
        switch count {
        case 0:  return 10
        case 1:  return 30
        default: return 30 * Int(pow(10.0, Double(count - 1)))
        }
    }

    var nextRecastCost: Int { Self.recastCost(forCount: recastCountToday) }

    private let storageKey = "dailyDivinationResult"
    private let historyKey = "divinationHistory"
    private let recastDateKey = "recastUsedDate"
    private let recastCountKey = "recastCountToday"
    private let syncMarkerKey = "dailySyncedOnce"
    private let historyLimit = 1000   // 每日可有多卦（重算保留全部）


    private let kv = NSUbiquitousKeyValueStore.default
    private var observer: NSObjectProtocol?

    init() {
        kv.synchronize()
        mergeAndLoad(cloudAuthoritativeForToday: kv.bool(forKey: syncMarkerKey))
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kv,
            queue: .main
        ) { [weak self] _ in
            self?.mergeAndLoad(cloudAuthoritativeForToday: true)
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Cached formatter — creating a DateFormatter per call is a classic main-thread cost.
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static var todayString: String {
        dayFormatter.string(from: Date())
    }

    // MARK: - Public API

    func save(values: [Int], question: String? = nil) {
        let trimmed = question?.trimmingCharacters(in: .whitespacesAndNewlines)
        let result = DivinationResult(values: values, dateString: Self.todayString,
                                      question: (trimmed?.isEmpty ?? true) ? nil : trimmed,
                                      epoch: Date().timeIntervalSince1970)
        todayResult = result
        // 评分请求计数：完成起卦的总次数（本地即可，无需同步）。
        let castCount = UserDefaults.standard.integer(forKey: "castCompletedCount") + 1
        UserDefaults.standard.set(castCount, forKey: "castCompletedCount")
        // Keep EVERY reading (recasts included), newest first.
        var list = history
        list.insert(result, at: 0)
        if list.count > historyLimit {
            list = Array(list.prefix(historyLimit))
        }
        history = list
        persist()
        WidgetBridge.update(result: result)
    }

    /// The app can stay in memory across midnight; re-derive "today" state.
    func refreshForNewDay() {
        refreshRecastCount()
        if let result = todayResult, result.dateString != Self.todayString {
            todayResult = nil
            persist()
            WidgetBridge.update(result: nil)
        }
    }

    /// Clears today's result for a paid recast (max 2/day).
    /// Coin deduction happens in the caller.
    func startRecast() {
        refreshRecastCount()
        recastCountToday += 1
        let defaults = UserDefaults.standard
        defaults.set(Self.todayString, forKey: recastDateKey)
        defaults.set(recastCountToday, forKey: recastCountKey)
        kv.set(Self.todayString, forKey: recastDateKey)
        kv.set(Int64(recastCountToday), forKey: recastCountKey)
        todayResult = nil
        persist()
        WidgetBridge.update(result: nil)
    }

    func resetToday() {
        recastCountToday = 0
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: recastDateKey)
        defaults.removeObject(forKey: recastCountKey)
        kv.removeObject(forKey: recastDateKey)
        kv.removeObject(forKey: recastCountKey)
        todayResult = nil
        persist()
        WidgetBridge.update(result: nil)
    }

    /// Today's recast count = max across the user's devices (synced via iCloud).
    private func refreshRecastCount() {
        let today = Self.todayString
        let defaults = UserDefaults.standard
        let local = defaults.string(forKey: recastDateKey) == today
            ? defaults.integer(forKey: recastCountKey) : 0
        let cloud = kv.string(forKey: recastDateKey) == today
            ? Int(kv.longLong(forKey: recastCountKey)) : 0
        recastCountToday = max(local, cloud)
    }

    // MARK: - Sync plumbing

    private static func decodeList(_ data: Data?) -> [DivinationResult] {
        guard let data,
              let list = try? JSONDecoder().decode([DivinationResult].self, from: data)
        else { return [] }
        return list
    }

    private static func decodeOne(_ data: Data?) -> DivinationResult? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(DivinationResult.self, from: data)
    }

    /// Merge local + cloud state, publish, and write back to both stores.
    /// `cloudAuthoritativeForToday`: once any device has synced, the cloud's
    /// today-slot (including its absence, i.e. a recast in progress) wins;
    /// on the very first sync the local value is preserved and pushed up.
    private func mergeAndLoad(cloudAuthoritativeForToday: Bool) {
        let defaults = UserDefaults.standard
        refreshRecastCount()
        // --- history: union by unique id (all readings survive, incl. recasts) ---
        var byUID: [String: DivinationResult] = [:]
        for r in Self.decodeList(defaults.data(forKey: historyKey))
               + Self.decodeList(kv.data(forKey: historyKey)) {
            byUID[r.uid] = r
        }
        history = Array(
            byUID.values.sorted {
                $0.dateString != $1.dateString
                    ? $0.dateString > $1.dateString
                    : ($0.epoch ?? 0) > ($1.epoch ?? 0)
            }
            .prefix(historyLimit)
        )
        // --- today's result ---
        let localToday = Self.decodeOne(defaults.data(forKey: storageKey))
            .flatMap { $0.dateString == Self.todayString ? $0 : nil }
        let cloudToday = Self.decodeOne(kv.data(forKey: storageKey))
            .flatMap { $0.dateString == Self.todayString ? $0 : nil }
        if cloudAuthoritativeForToday {
            todayResult = cloudToday
        } else {
            // First-ever sync: keep whichever exists (prefer newer epoch).
            todayResult = [localToday, cloudToday].compactMap { $0 }
                .max { ($0.epoch ?? 0) < ($1.epoch ?? 0) }
        }
        persist()
        WidgetBridge.update(result: todayResult)
    }

    private func persist() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: historyKey)
            kv.set(data, forKey: historyKey)
        }
        if let result = todayResult, let data = try? JSONEncoder().encode(result) {
            defaults.set(data, forKey: storageKey)
            kv.set(data, forKey: storageKey)
        } else {
            defaults.removeObject(forKey: storageKey)
            kv.removeObject(forKey: storageKey)
        }
        kv.set(true, forKey: syncMarkerKey)
        kv.synchronize()
    }
}
