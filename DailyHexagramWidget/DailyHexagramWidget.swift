import WidgetKit
import SwiftUI

// MARK: - Shared snapshot (keep field names in sync with the app's WidgetBridge.Snapshot)

struct HexSnapshot: Codable {
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
    var xiangZh: String? = nil
    var xiangEn: String? = nil
}

private enum Shared {
    static let appGroup = "group.com.dj.DailyHexagram"
    static let snapshotKey = "widgetSnapshot"
    static let premiumKey = "widgetPremium"
    static let langKey = "widgetLang"

    static func load() -> (snapshot: HexSnapshot?, isPremium: Bool, lang: String) {
        guard let defaults = UserDefaults(suiteName: appGroup) else { return (nil, false, "zh") }
        var snapshot: HexSnapshot? = nil
        if let data = defaults.data(forKey: snapshotKey) {
            snapshot = try? JSONDecoder().decode(HexSnapshot.self, from: data)
        }
        let lang = defaults.string(forKey: langKey) ?? "zh"
        return (snapshot, defaults.bool(forKey: premiumKey), lang)
    }

    static var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: Date())
    }
}

// MARK: - Timeline

struct HexEntry: TimelineEntry {
    let date: Date
    let snapshot: HexSnapshot?
    let isPremium: Bool
    let lang: String
}

struct HexProvider: TimelineProvider {
    func placeholder(in context: Context) -> HexEntry {
        HexEntry(date: .now, snapshot: sample, isPremium: true, lang: "zh")
    }

    func getSnapshot(in context: Context, completion: @escaping (HexEntry) -> Void) {
        if context.isPreview {
            completion(HexEntry(date: .now, snapshot: sample, isPremium: true, lang: "zh"))
        } else {
            completion(makeEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HexEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh at next midnight so a stale hexagram never lingers.
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func makeEntry() -> HexEntry {
        let shared = Shared.load()
        // Only surface a snapshot cast today.
        let valid = shared.snapshot?.dateString == Shared.todayString ? shared.snapshot : nil
        return HexEntry(date: .now, snapshot: valid, isPremium: shared.isPremium, lang: shared.lang)
    }

    private var sample: HexSnapshot {
        HexSnapshot(dateString: Shared.todayString, symbol: "䷊",
                    nameZh: "第11卦 · 地天泰", nameEn: "Hexagram 11 · Peace (Tài)",
                    levelZh: "大吉", levelEn: "Very Auspicious",
                    guaciZh: "泰：小往大来，吉亨。",
                    guaciEn: "Peace: the small departs, the great approaches.",
                    modernZh: "天地交而万物通。今日运势通泰，诸事顺遂。",
                    modernEn: "Heaven and earth unite: an excellent day, everything flows.",
                    xiangZh: "天地交，泰。",
                    xiangEn: "Heaven and earth unite: peace.")
    }
}

// MARK: - Views

/// Simplified→Traditional conversion for the widget (mirrors the app's `Lang`).
private enum Hant {
    private static let cache = NSCache<NSString, NSString>()
    static func convert(_ s: String) -> String {
        if let hit = cache.object(forKey: s as NSString) { return hit as String }
        let out = (s as NSString).applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? s
        cache.setObject(out as NSString, forKey: s as NSString)
        return out
    }
}

struct HexWidgetView: View {
    let entry: HexEntry
    @Environment(\.widgetFamily) private var family

    private var zh: Bool { entry.lang != "en" }
    /// Chinese display text, converted when the app language is 繁體.
    private func zhs(_ s: String) -> String {
        entry.lang == "zht" ? Hant.convert(s) : s
    }

    var body: some View {
        Group {
            if !entry.isPremium {
                lockedView
            } else if let snapshot = entry.snapshot {
                switch family {
                case .systemMedium: mediumView(snapshot)
                case .systemLarge: largeView(snapshot)
                default: smallView(snapshot)
                }
            } else {
                notCastView
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color(red: 0.11, green: 0.09, blue: 0.17),
                                    Color(red: 0.04, green: 0.03, blue: 0.06)],
                           startPoint: .top, endPoint: .bottom)
        }
    }

    private let gold = Color(red: 0.87, green: 0.72, blue: 0.37)

    private var lockedView: some View {
        VStack(spacing: 6) {
            Image(systemName: "crown.fill")
                .font(.title3)
                .foregroundStyle(gold)
            Text(zh ? zhs("每日一卦") : "Daily Hexagram")
                .font(.headline)
                .foregroundStyle(.white)
            Text(zh ? zhs("小组件为会员专属\n在 App 中开通") : "Widget is a Premium feature.\nUnlock in the app.")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    private var notCastView: some View {
        VStack(spacing: 6) {
            Text("☰")
                .font(.title2)
                .foregroundStyle(gold)
            Text(zh ? zhs("今日尚未起卦") : "Not cast yet today")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
            Text(zh ? zhs("打开 App 掷币起卦") : "Open the app to cast")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    private func levelBadge(_ s: HexSnapshot) -> some View {
        Text(zh ? zhs(s.levelZh) : s.levelEn)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Capsule().fill(gold.opacity(0.2)))
            .foregroundStyle(gold)
    }

    private func smallView(_ s: HexSnapshot) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Text(s.symbol)
                    .font(.system(size: 26))
                    .foregroundStyle(gold)
                Text(zh ? zhs(shortName(s.nameZh)) : shortName(s.nameEn))
                    .font(.footnote.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            levelBadge(s)
            // 今日解读摘要
            Text(zh ? zhs(s.modernZh) : s.modernEn)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(4)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.leading)
        }
    }

    private func mediumView(_ s: HexSnapshot) -> some View {
        HStack(spacing: 14) {
            VStack(spacing: 4) {
                Text(s.symbol)
                    .font(.system(size: 44))
                    .foregroundStyle(gold)
                levelBadge(s)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(zh ? zhs(s.nameZh) : s.nameEn)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(zh ? zhs(s.guaciZh) : s.guaciEn)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                // 今日解读
                Text(zh ? zhs(s.modernZh) : s.modernEn)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(4)
            }
            Spacer(minLength: 0)
        }
    }

    private func largeView(_ s: HexSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(s.symbol)
                    .font(.system(size: 44))
                    .foregroundStyle(gold)
                VStack(alignment: .leading, spacing: 3) {
                    Text(zh ? zhs(s.nameZh) : s.nameEn)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    levelBadge(s)
                }
                Spacer(minLength: 0)
            }
            Divider().overlay(gold.opacity(0.35))
            Text(zh ? zhs(s.guaciZh) : s.guaciEn)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(2)
            if let xiang = zh ? s.xiangZh : (s.xiangEn ?? s.xiangZh), !xiang.isEmpty {
                Text(zh ? zhs("象曰：\(xiang)") : xiang)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(2)
            }
            // 今日解读（完整）
            Text(zh ? zhs(s.modernZh) : s.modernEn)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(7)
            Spacer(minLength: 0)
        }
    }

    /// "第11卦 · 地天泰" → "地天泰"; "Hexagram 11 · Peace (Tài)" → "Peace (Tài)"
    private func shortName(_ full: String) -> String {
        full.components(separatedBy: "· ").last ?? full
    }
}

// MARK: - Widget

struct DailyHexagramWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DailyHexagramWidget", provider: HexProvider()) { entry in
            HexWidgetView(entry: entry)
        }
        .configurationDisplayName("每日一卦 · Daily Hexagram")
        .description("今日卦象一览（会员专属）· Today's hexagram at a glance (Premium).")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct DailyHexagramWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyHexagramWidget()
    }
}
