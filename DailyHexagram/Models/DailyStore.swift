import Foundation
import SwiftUI

/// Persists today's divination and enforces the once-per-day rule.
final class DailyStore: ObservableObject {
    @Published private(set) var todayResult: DivinationResult?
    @Published private(set) var recastUsedToday: Bool
    @Published private(set) var history: [DivinationResult] = []

    private let storageKey = "dailyDivinationResult"
    private let recastKey = "recastUsedDate"
    private let historyKey = "divinationHistory"
    private let historyLimit = 366

    init() {
        recastUsedToday = UserDefaults.standard.string(forKey: "recastUsedDate") == Self.todayString
        loadHistory()
        load()
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

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let result = try? JSONDecoder().decode(DivinationResult.self, from: data),
              result.dateString == Self.todayString
        else {
            todayResult = nil
            WidgetBridge.update(result: nil)
            return
        }
        todayResult = result
        WidgetBridge.update(result: result)
    }

    func save(values: [Int], question: String? = nil) {
        let trimmed = question?.trimmingCharacters(in: .whitespacesAndNewlines)
        let result = DivinationResult(values: values, dateString: Self.todayString,
                                      question: (trimmed?.isEmpty ?? true) ? nil : trimmed)
        if let data = try? JSONEncoder().encode(result) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        todayResult = result
        appendToHistory(result)
        WidgetBridge.update(result: result)
    }

    // MARK: - History

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let list = try? JSONDecoder().decode([DivinationResult].self, from: data)
        else { return }
        history = list
    }

    private func appendToHistory(_ result: DivinationResult) {
        // Replace any same-day entry (recast), newest first.
        var list = history.filter { $0.dateString != result.dateString }
        list.insert(result, at: 0)
        if list.count > historyLimit {
            list = Array(list.prefix(historyLimit))
        }
        history = list
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    /// The app can stay in memory across midnight; re-derive all "today" state.
    func refreshForNewDay() {
        let usedToday = UserDefaults.standard.string(forKey: recastKey) == Self.todayString
        if recastUsedToday != usedToday {
            recastUsedToday = usedToday
        }
        if let result = todayResult, result.dateString != Self.todayString {
            load()   // yesterday's result: clear and update the widget
        }
    }

    /// Clears today's result to allow one paid recast. Coin deduction happens in the caller.
    func startRecast() {
        UserDefaults.standard.set(Self.todayString, forKey: recastKey)
        UserDefaults.standard.removeObject(forKey: storageKey)
        recastUsedToday = true
        todayResult = nil
        WidgetBridge.update(result: nil)
    }

    func resetToday() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        UserDefaults.standard.removeObject(forKey: recastKey)
        recastUsedToday = false
        todayResult = nil
        WidgetBridge.update(result: nil)
    }
}
