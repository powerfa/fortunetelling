import Foundation

/// Language routing: "zh" 简体 · "zht" 繁體 · "en" English.
/// Traditional Chinese is derived from the Simplified source via ICU's
/// Hans-Hant transliterator (cached), so every string stays in sync.
enum Lang {
    static func isChinese(_ lang: String) -> Bool { lang != "en" }

    /// Pick the display string for the language, converting to Traditional if needed.
    static func choose(_ zh: String, _ en: String, _ lang: String) -> String {
        lang == "en" ? en : hant(zh, lang)
    }

    /// Convert a Simplified string when the language is Traditional.
    static func hant(_ zh: String, _ lang: String) -> String {
        lang == "zht" ? convert(zh) : zh
    }

    private static let cache = NSCache<NSString, NSString>()

    static func convert(_ s: String) -> String {
        if let hit = cache.object(forKey: s as NSString) { return hit as String }
        let out = (s as NSString).applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? s
        cache.setObject(out as NSString, forKey: s as NSString)
        return out
    }
}

/// Simple in-app bilingual string table, driven by @AppStorage("appLanguage").
enum L10n {
    private static let table: [String: (zh: String, en: String)] = [
        "app_title":       ("每日一卦", "Daily Hexagram"),
        "cast_prompt":     ("诚心默念所问之事，掷币六次，自下而上成卦", "Hold your question in mind, then toss six times"),
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
        "three_no":        ("不诚不占 · 不义不占 · 不疑不占", "Sincerity · Righteousness · True doubt"),
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
        "check_in":        ("每日签到", "Daily Check-in"),
        "checked_in":      ("今日已签到", "Checked in today"),
        "checkin_rule":    ("签到奖励：每日 +1 福币，会员 +2。红圈为已签到日。", "Check-in reward: +1 coin daily, +2 with Premium. Red circles mark checked-in days."),
        "premium_title":   ("会员", "Premium"),
        "premium_benefits": ("· 事业、爱情、财运、健康四维深度详批\n· 桌面小组件：每日卦象一览\n· 每日签到双倍福币", "· In-depth readings: career, love, wealth & health\n· Home Screen widget: today's hexagram at a glance\n· Double daily check-in coins"),
        "premium_active":  ("会员已开通", "Premium is active"),
        "restore":         ("恢复购买", "Restore Purchases"),
        "coin_packs":      ("福币充值", "Coin Packs"),
        "store_unavailable": ("商店暂不可用：请在 Xcode Scheme 中启用 StoreKit 配置，或上架 App Store Connect 后生效。", "Store unavailable: enable the StoreKit configuration in your Xcode scheme, or configure products in App Store Connect."),
        // Tabs
        "tab_today":       ("算卦", "Divine"),
        "tab_blessing":    ("祈福", "Blessing"),
        "tab_history":     ("历史", "History"),
        "tab_guide":       ("知识", "Learn"),
        // Incense (上香)
        "tab_incense":     ("上香", "Incense"),
        "incense_subtitle": ("焚香一炷，心诚则灵", "One stick of incense, offered with a sincere heart"),
        "incense_hint":    ("长按香炉点香，或一键上香", "Long-press the censer to light, or use the button"),
        "incense_button":  ("一键上香 · 10 福币", "Light Incense · 10 coins"),
        "incense_confirm_title": ("上香祈愿", "Offer Incense"),
        "incense_confirm_msg": ("心中默念所求之事。一炷心香将燃烧真实时长，燃尽时提醒您。消耗 10 福币。", "Hold your prayer silently in mind. The incense burns in real time; you'll be notified when it finishes. Costs 10 coins."),
        "light_action":    ("点香", "Light"),
        "incense_burning": ("一炷心香 · 剩余 %@", "Incense burning · %@ left"),
        "incense_done_title": ("香已上完", "The incense has burned out"),
        "incense_count":   ("已上香 %d 次", "Offered %d times"),
        // Blessing tree (祈福)
        "blessing_subtitle": ("许愿树每日焕新，今日心愿今日挂", "The wish tree renews daily — today's wishes hang today"),
        "charm_shop":      ("请符", "Charms"),
        "free_today_badge": ("今日首符免费", "First charm free today"),
        "free_label":      ("免费", "Free"),
        "write_wish":      ("写下心愿", "Write Your Wish"),
        "wish_placeholder": ("写下你的心愿…", "Write your wish…"),
        "hang_on_tree":    ("挂上许愿树", "Hang on the Tree"),
        "tree_full":       ("今日树上已挂满，明日再来", "The tree is full for today — come back tomorrow"),
        "blessed_note":    ("符者，心之所寄。仅供祈愿娱乐。", "A charm carries the heart's intent. For reflection and fun only."),
        // Question (所问之事)
        "question_placeholder": ("所问何事？（可留空）", "Your question (optional)"),
        "question_label":  ("所问", "Question"),
        "default_question": ("今日运势", "Today's fortune"),
        // 象传
        "xiang":           ("象曰", "The Image"),
        // History
        "history_title":   ("历史", "History"),
        "hist_seg_cast":   ("卦象", "Readings"),
        "hist_seg_blessing": ("祈福", "Wishes"),
        "hist_seg_incense": ("上香", "Incense"),
        "blessing_history_empty": ("还没有祈福记录。去许愿树上挂一枚心愿符吧。", "No wishes yet. Hang a charm on the wish tree."),
        "incense_history_empty": ("还没有上香记录。焚一炷心香，静心凝神。", "No incense offerings yet. Light one to settle the mind."),
        "history_empty":   ("尚无占卜记录。每日一占，回头验证，是了解易经最好的方式。", "No readings yet. Cast daily and revisit — checking past readings against reality is the best way to learn the I Ching."),
        "history_hint":    ("回顾过往卦象，验证解读与实际的对照。", "Revisit past readings and see how they matched reality."),
        // Share
        "share":           ("分享卦象", "Share Reading"),
        // Guide
        "guide_title":     ("易经知识", "About the I Ching"),
        // Sound & shake
        "sound":           ("音效", "Sound Effects"),
        "incense_music":   ("焚香音乐", "Incense Music"),
        "shake_hint":      ("也可以摇一摇手机掷币", "…or shake your phone to toss"),
        // Product names (shown instead of StoreKit displayName, so they follow the app language)
        "prod_monthly":    ("月度会员", "Premium Monthly"),
        "prod_yearly":     ("年度会员", "Premium Yearly"),
        "prod_coins30":    ("30 福币", "30 Coins"),
        "prod_coins180":   ("180 福币", "180 Coins"),
        "prod_coins800":   ("800 福币", "800 Coins"),
        "prod_coins2500":  ("2500 福币", "2500 Coins"),
        "save_pct":        ("省 %d%%", "Save %d%%"),
        "best_value":      ("最划算", "Best Value"),
        "debug_premium_on":  ("测试：开启会员", "Debug: Enable Premium"),
        "debug_premium_off": ("测试：关闭会员", "Debug: Disable Premium"),
        // Invite friends
        "invite_title":        ("邀请好友", "Invite Friends"),
        "invite_row":          ("邀请好友 · 各得 %d 福币", "Invite friends · %d coins each"),
        "invite_rule":         ("邀请好友使用本 App：好友输入你的邀请码后，你们双方各得 %d 福币。最多可获得 %d 位好友的邀请奖励。", "When a friend enters your invite code, you both receive %d coins. Rewards apply for up to %d friends."),
        "my_invite_code":      ("我的邀请码", "My Invite Code"),
        "invite_generate":     ("生成我的邀请码", "Generate My Code"),
        "invite_share":        ("分享", "Share"),
        "invite_share_text":   ("我在用「每日一卦」，每天一占，观象修身。下载后在商店页输入我的邀请码，你我各得 %d 福币！\n邀请码：%@", "I'm using Daily Hexagram — one I Ching reading a day. Enter my invite code after installing and we each get %d coins!\nCode: %@"),
        "copy":                ("复制", "Copy"),
        "copied":              ("已复制", "Copied"),
        "invite_progress":     ("已成功邀请 %d 人 · 累计获得 %d 福币", "%d friends joined · %d coins earned"),
        "enter_invite_code":   ("兑换码（邀请码 / 礼品码）", "Redeem a Code (Invite / Gift)"),
        "invite_code_placeholder": ("输入邀请码或礼品码", "Invite or gift code"),
        "gift_success":        ("礼品码兑换成功，福币 +%d！", "Gift code redeemed — +%d coins!"),
        "gift_already":        ("这个礼品码你已经兑换过了", "You've already redeemed this gift code"),
        "gift_unavailable":    ("该礼品码已失效、过期或已被兑完", "This gift code is inactive, expired, or fully redeemed"),
        "redeem":              ("兑换", "Redeem"),
        "invite_redeemed":     ("已兑换过邀请码", "Invite code already redeemed"),
        "invite_success":      ("兑换成功，福币 +%d！", "Success — +%d coins!"),
        "invite_already":      ("每个 iCloud 账号只能兑换一次", "Each iCloud account can redeem only once"),
        "invite_self":         ("不能兑换自己的邀请码", "You can't redeem your own code"),
        "invite_invalid":      ("兑换码不存在，请核对后重试", "Code not found — please check and retry"),
        "invite_error":        ("网络或 iCloud 暂时不可用，请稍后再试", "Network or iCloud temporarily unavailable — try again later"),
        "invite_need_icloud":  ("请先在系统设置中登录 iCloud", "Please sign in to iCloud in Settings first"),
        "invite_reward_arrived": ("你邀请的好友已加入，福币 +%d！", "Your invited friends joined — +%d coins!"),
        // Store compliance
        "sub_note":          ("订阅按所选周期自动续费，到期前 24 小时内扣费；可随时在 App Store 账户设置中取消。", "Subscriptions renew automatically for the selected period and are charged within 24 hours before renewal. Cancel anytime in your App Store account settings."),
        "terms_of_use":      ("使用条款", "Terms of Use"),
        "privacy_policy":    ("隐私政策", "Privacy Policy"),
        "purchase_failed_title": ("购买未完成", "Purchase Incomplete"),
        "purchase_pending_title": ("等待批准", "Pending Approval"),
        "purchase_pending_msg": ("购买请求已发送，批准后将自动到账。", "Your purchase request was sent and will complete automatically once approved."),
        "ok":                ("好", "OK"),
        "version":           ("版本", "Version"),
        // Onboarding
        "ob_welcome":        ("欢迎", "Welcome"),
        "ob_title":          ("每日一卦", "Daily Hexagram"),
        "ob_intro":          ("以《周易》六十四卦观照每一天", "See each day through the 64 hexagrams of the I Ching"),
        "ob_cast_title":     ("每日一占", "One Reading a Day"),
        "ob_cast_body":      ("默念所问之事，掷三枚铜钱六次，自下而上成卦。每天只占一次，静心以待。", "Hold your question in mind and toss three coins six times to build your hexagram. One reading per day."),
        "ob_sincere_title":  ("三不占", "Three Don'ts"),
        "ob_sincere_body":   ("不诚不占，不义不占，不疑不占。卦象是参考，决定始终在你。", "No sincerity, no reading; no righteousness, no reading; no true doubt, no reading. The hexagram advises — the decision is yours."),
        "ob_more_title":     ("祈福与上香", "Blessings & Incense"),
        "ob_more_body":      ("请符挂愿上许愿树，焚一炷心香静心凝神。福币可通过每日签到获得。", "Hang wishes on the tree and offer incense to settle the mind. Earn coins with daily check-ins."),
        "ob_note":           ("所有内容仅供参考与自省，不构成专业建议。", "Everything here is for reflection only, not professional advice."),
        "ob_start":          ("开始", "Begin"),
    ]

    static func t(_ key: String, _ lang: String) -> String {
        guard let pair = table[key] else { return key }
        return Lang.choose(pair.zh, pair.en, lang)
    }

    /// Description of one coin toss outcome (value 6/7/8/9).
    static func lineName(for value: Int, lang: String) -> String {
        switch value {
        case 6:  return Lang.choose("三阴面 · 老阴 ✕（变爻）", "Three tails · Old Yin ✕ (changing)", lang)
        case 7:  return Lang.choose("一阳两阴 · 少阳 ⚊", "One head, two tails · Young Yang ⚊", lang)
        case 8:  return Lang.choose("两阳一阴 · 少阴 ⚋", "Two heads, one tail · Young Yin ⚋", lang)
        default: return Lang.choose("三阳面 · 老阳 ○（变爻）", "Three heads · Old Yang ○ (changing)", lang)
        }
    }

    /// Traditional name of a changing line, e.g. 初九 / 六三 / 上六.
    static func changingLineName(index: Int, value: Int, lang: String) -> String {
        if Lang.isChinese(lang) {
            let pos = ["初", "二", "三", "四", "五", "上"][index]
            let type = value == 9 ? "九" : "六"
            return (index == 0 || index == 5) ? "\(pos)\(type)" : "\(type)\(pos)"
        } else {
            return "Line \(index + 1) (\(value == 9 ? "Old Yang" : "Old Yin"))"
        }
    }

    // Cached date formatters (rebuilding them on every view render causes jank).
    private static let zhDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateStyle = .full
        return f
    }()
    private static let zhtDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.dateStyle = .full
        return f
    }()
    private static let enDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateStyle = .full
        return f
    }()

    static func dateText(lang: String) -> String {
        switch lang {
        case "zh":  return zhDateFormatter.string(from: Date())
        case "zht": return zhtDateFormatter.string(from: Date())
        default:    return enDateFormatter.string(from: Date())
        }
    }
}
