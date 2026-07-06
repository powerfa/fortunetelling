import Foundation
import WidgetKit

/// Writes today's result + premium/language state into the App Group so the
/// widget extension can render it. Keep `Snapshot` in sync with the widget's `HexSnapshot`.
enum WidgetBridge {
    static let appGroup = "group.com.dj.DailyHexagram"
    static let snapshotKey = "widgetSnapshot"
    static let premiumKey = "widgetPremium"
    static let langKey = "widgetLang"

    struct Snapshot: Codable {
        let dateString: String
        let symbol: String
        let nameZh: String
        let nameEn: String
        let levelZh: String
        let levelEn: String
        let guaciZh: String
        let guaciEn: String
        let modernZh: String
        let modernEn: String
        let xiangZh: String
        let xiangEn: String
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }

    /// All writers skip the (expensive) timeline reload when nothing actually changed —
    /// e.g. every app launch re-writes the same snapshot.
    static func update(result: DivinationResult?) {
        guard let defaults else { return }
        var newData: Data? = nil
        if let result {
            let hex = result.primary
            let snapshot = Snapshot(
                dateString: result.dateString,
                symbol: hex.symbol,
                nameZh: hex.name("zh"),
                nameEn: hex.name("en"),
                levelZh: hex.levelZh,
                levelEn: hex.levelEn,
                guaciZh: hex.guaciZh,
                guaciEn: hex.guaciEn,
                modernZh: hex.modernZh,
                modernEn: hex.modernEn,
                xiangZh: hex.xiangZh,
                xiangEn: hex.xiangEn
            )
            newData = try? JSONEncoder().encode(snapshot)
        }
        guard defaults.data(forKey: snapshotKey) != newData else { return }
        if let newData {
            defaults.set(newData, forKey: snapshotKey)
        } else {
            defaults.removeObject(forKey: snapshotKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func setPremium(_ isPremium: Bool) {
        guard let defaults, defaults.bool(forKey: premiumKey) != isPremium else { return }
        defaults.set(isPremium, forKey: premiumKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func setLanguage(_ lang: String) {
        guard let defaults, defaults.string(forKey: langKey) != lang else { return }
        defaults.set(lang, forKey: langKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
