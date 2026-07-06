import Foundation

/// Simple in-app bilingual string table, driven by @AppStorage("appLanguage").
enum L10n {
    private static let table: [String: (zh: String, en: String)] = [
        "app_title":       ("每日一卦", "Daily Hexagram"),
        "cast_prompt":     ("诚心默念所问之事，掷币六次，自下而上成卦", "Hold your question in mind, then toss the coins six times to build the hexagram from the bottom up"),
        "toss_button":     ("掷  币", "Toss Coins"),
        "toss_progress":   ("第 %d 爻 · 共六爻", "Line %d of 6"),
        "reveal_button":   ("查看卦象", "Reveal Hexagram"),
        "already_cast":    ("今日已起卦 · 明日再来", "Today's reading is done · come back tomorrow"),
        "judgment":        ("卦辞", "The Judgment"),
        "interpretation":  ("今日解读", "Today's Reading"),
        "changing_lines":  ("变爻", "Changing Lines"),
        "future_hexagram": ("变卦", "Transformed Hexagram"),
        "settings":        ("设置", "Settings"),
        "language":        ("语言 / Language", "Language / 语言"),
        "about":           ("关于", "About"),
        "about_text":      ("以《周易》六十四卦为核心，采用传统三枚铜钱起卦法，每日一占。结果仅供参考娱乐。", "Based on the 64 hexagrams of the I Ching, using the traditional three-coin method. One reading per day. For reflection and entertainment only."),
        "reset_today":     ("重置今日卦象（测试用）", "Reset Today's Cast (for testing)"),
        "disclaimer":      ("结果仅供参考娱乐", "For reflection and entertainment only"),
        "done":            ("完成", "Done"),
        // 曾仕强「三不占」
        "three_no":        ("不诚不占 · 不义不占 · 不疑不占", "Divine only with sincerity, for what is right, and when truly in doubt"),
        // Premium detail readings
        "premium_section": ("四维详批", "Detailed Reading"),
        "career":          ("事业", "Career"),
        "love":            ("爱情", "Love"),
        "wealth":          ("财运", "Wealth"),
        "health":          ("健康", "Health"),
        "unlock_premium":  ("开通会员，解锁事业·爱情·财运·健康详批", "Unlock Premium for career, love, wealth & health readings"),
        "go_premium":      ("开通会员", "Go Premium"),
        // Coins & recast
        "recast_button":   ("重新起卦 · 10 福币", "Recast · 10 coins"),
        "recast_used":     ("今日重算机会已用完，明日再来", "Today's recast has been used — come back tomorrow"),
        "recast_confirm_title": ("消耗 10 福币重新起卦？", "Spend 10 coins to recast?"),
        "recast_confirm_msg": ("每天仅可重算一次，当前卦象将被替换。", "You may recast only once per day. The current reading will be replaced."),
        "confirm":         ("确定", "Confirm"),
        "cancel":          ("取消", "Cancel"),
        "not_enough_coins": ("福币不足，去获取", "Not enough coins — get more"),
        // Store
        "store_title":     ("福币与会员", "Coins & Premium"),
        "balance":         ("当前福币", "Coin Balance"),
        "check_in":        ("每日签到 +2 福币", "Daily Check-in +2 Coins"),
        "checked_in":      ("今日已签到", "Checked in today"),
        "premium_title":   ("会员", "Premium"),
        "premium_benefits": ("· 事业、爱情、财运、健康四维深度详批\n· 桌面小组件：每日卦象一览", "· In-depth readings: career, love, wealth & health\n· Home Screen widget: today's hexagram at a glance"),
        "premium_active":  ("会员已开通", "Premium is active"),
        "restore":         ("恢复购买", "Restore Purchases"),
        "coin_packs":      ("福币充值", "Coin Packs"),
        "store_unavailable": ("商店暂不可用：请在 Xcode Scheme 中启用 StoreKit 配置，或上架 App Store Connect 后生效。", "Store unavailable: enable the StoreKit configuration in your Xcode scheme, or configure products in App Store Connect."),
        // Tabs
        "tab_today":       ("今日", "Today"),
        "tab_history":     ("历史", "History"),
        "tab_guide":       ("知识", "Learn"),
        // Question (所问之事)
        "question_placeholder": ("所问何事？（可留空，默认问今日运势）", "What is your question? (optional — defaults to today's fortune)"),
        "question_label":  ("所问", "Question"),
        "default_question": ("今日运势", "Today's fortune"),
        // 象传
        "xiang":           ("象曰", "The Image"),
        // History
        "history_title":   ("占卜历史", "Reading History"),
        "history_empty":   ("尚无占卜记录。每日一占，回头验证，是了解易经最好的方式。", "No readings yet. Cast daily and revisit — checking past readings against reality is the best way to learn the I Ching."),
        "history_hint":    ("回顾过往卦象，验证解读与实际的对照。", "Revisit past readings and see how they matched reality."),
        // Share
        "share":           ("分享卦象", "Share Reading"),
        // Guide
        "guide_title":     ("易经知识", "About the I Ching"),
        // Sound & shake
        "sound":           ("音效", "Sound Effects"),
        "shake_hint":      ("也可以摇一摇手机掷币", "…or shake your phone to toss"),
        // Product names (shown instead of StoreKit displayName, so they follow the app language)
        "prod_monthly":    ("月度会员", "Premium Monthly"),
        "prod_yearly":     ("年度会员", "Premium Yearly"),
        "prod_coins60":    ("60 福币", "60 Coins"),
        "prod_coins200":   ("200 福币", "200 Coins"),
        "prod_coins600":   ("600 福币", "600 Coins"),
        "debug_premium_on":  ("测试：开启会员", "Debug: Enable Premium"),
        "debug_premium_off": ("测试：关闭会员", "Debug: Disable Premium"),
    ]

    static func t(_ key: String, _ lang: String) -> String {
        guard let pair = table[key] else { return key }
        return lang == "zh" ? pair.zh : pair.en
    }

    /// Description of one coin toss outcome (value 6/7/8/9).
    static func lineName(for value: Int, lang: String) -> String {
        switch value {
        case 6:  return lang == "zh" ? "三阴面 · 老阴 ✕（变爻）" : "Three tails · Old Yin ✕ (changing)"
        case 7:  return lang == "zh" ? "一阳两阴 · 少阳 ⚊" : "One head, two tails · Young Yang ⚊"
        case 8:  return lang == "zh" ? "两阳一阴 · 少阴 ⚋" : "Two heads, one tail · Young Yin ⚋"
        default: return lang == "zh" ? "三阳面 · 老阳 ○（变爻）" : "Three heads · Old Yang ○ (changing)"
        }
    }

    /// Traditional name of a changing line, e.g. 初九 / 六三 / 上六.
    static func changingLineName(index: Int, value: Int, lang: String) -> String {
        if lang == "zh" {
            let pos = ["初", "二", "三", "四", "五", "上"][index]
            let type = value == 9 ? "九" : "六"
            return (index == 0 || index == 5) ? "\(pos)\(type)" : "\(type)\(pos)"
        } else {
            return "Line \(index + 1) (\(value == 9 ? "Old Yang" : "Old Yin"))"
        }
    }

    static func dateText(lang: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: lang == "zh" ? "zh_CN" : "en_US")
        f.dateStyle = .full
        return f.string(from: Date())
    }
}
