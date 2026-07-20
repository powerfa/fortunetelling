import Foundation
import UserNotifications

/// 每日提醒：用户自选时间的本地通知，邀请其起今日一卦。
enum DailyReminder {
    static let identifier = "dailyCastReminder"
    /// Default 08:00, stored as minutes from midnight in @AppStorage.
    static let defaultMinutes = 8 * 60

    /// Re-schedule (or cancel) the repeating daily notification.
    static func update(enabled: Bool, minutes: Int, lang: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard enabled else { return }
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = Lang.choose("每日一卦", "Daily Hexagram", lang)
            content.body = Lang.choose("晨起一卦，静观今日。诚心默念所问之事，掷币起卦。",
                                       "A quiet moment to cast today's hexagram. Hold your question in mind.",
                                       lang)
            content.sound = .default
            var components = DateComponents()
            components.hour = minutes / 60
            components.minute = minutes % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            center.add(UNNotificationRequest(identifier: identifier,
                                             content: content, trigger: trigger))
        }
    }
}
