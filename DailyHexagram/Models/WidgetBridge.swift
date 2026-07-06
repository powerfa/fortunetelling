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

    static func update(result: DivinationResult?) {
        guard let defaults else { return }
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
            if let data = try? JSONEncoder().encode(snapshot) {
                defaults.set(data, forKey: snapshotKey)
            }
        } else {
            defaults.removeObject(forKey: snapshotKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func setPremium(_ isPremium: Bool) {
        defaults?.set(isPremium, forKey: premiumKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func setLanguage(_ lang: String) {
        defaults?.set(lang, forKey: langKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
