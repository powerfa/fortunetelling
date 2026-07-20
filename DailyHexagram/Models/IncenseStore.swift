import Foundation

/// One completed incense offering (for the history tab).
struct IncenseRecord: Codable, Identifiable {
    let id: UUID
    let date: Date          // completion time
}

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
    /// Completed offerings, newest first (history tab).
    @Published private(set) var records: [IncenseRecord] = []
    /// The incense finished while the app was closed — surface it once.
    @Published var pendingCompletion = false

    private let startKey = "incenseStart"
    private let countKey = "incenseCount"
    private let recordsKey = "incenseRecords"
    private let recordsLimit = 500

    private let kv = NSUbiquitousKeyValueStore.default
    private var observer: NSObjectProtocol?

    init() {
        kv.synchronize()
        totalCount = 0
        mergeAndLoad()
        // The physical burn stays device-local (only the device that lit it
        // tracks and completes it); completed records sync across devices.
        let ts = UserDefaults.standard.double(forKey: startKey)
        if ts > 0 {
            let start = Date(timeIntervalSince1970: ts)
            if Date() >= start.addingTimeInterval(Self.duration) {
                UserDefaults.standard.removeObject(forKey: startKey)
                totalCount += 1
                appendRecord(at: start.addingTimeInterval(Self.duration))
                pendingCompletion = true
            } else {
                burningStart = start
            }
        }
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kv,
            queue: .main
        ) { [weak self] _ in
            self?.mergeAndLoad()
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Merge local + cloud records (union by id) and counts (max), persist both.
    private func mergeAndLoad() {
        let defaults = UserDefaults.standard
        let decode: (Data?) -> [IncenseRecord] = { data in
            guard let data,
                  let list = try? JSONDecoder().decode([IncenseRecord].self, from: data)
            else { return [] }
            return list
        }
        var seen = Set<UUID>()
        let merged = (decode(defaults.data(forKey: recordsKey)) + decode(kv.data(forKey: recordsKey)))
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.date > $1.date }
        records = Array(merged.prefix(recordsLimit))
        totalCount = max(defaults.integer(forKey: countKey),
                         Int(kv.longLong(forKey: countKey)),
                         records.count)
        persist()
    }

    private func appendRecord(at date: Date) {
        records.insert(IncenseRecord(id: UUID(), date: date), at: 0)
        if records.count > recordsLimit {
            records = Array(records.prefix(recordsLimit))
        }
        persist()
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(totalCount, forKey: countKey)
        kv.set(Int64(totalCount), forKey: countKey)
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: recordsKey)
            kv.set(data, forKey: recordsKey)
        }
        kv.synchronize()
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
        appendRecord(at: Date())
    }
}
