import SwiftUI

/// 易经知识：讲清起卦原理、概率与解卦规则 —— 透明是可信度的根基。
struct GuideView: View {
    @AppStorage("appLanguage") private var lang = "zh"

    private struct Topic: Identifiable {
        let id: Int
        let icon: String
        let titleZh: String, titleEn: String
        let bodyZh: String, bodyEn: String
    }

    private let topics: [Topic] = [
        Topic(id: 1, icon: "book.closed.fill",
            titleZh: "什么是六十四卦",
            titleEn: "What Are the 64 Hexagrams",
            bodyZh: "《周易》以阴（⚋）阳（⚊）两种爻为基本符号，三爻成一经卦（八卦：乾☰、兑☱、离☲、震☳、巽☴、坎☵、艮☶、坤☷），两经卦上下相叠，即得六十四别卦。每卦有卦辞（周文王所系），每爻有爻辞，孔门后学又作《易传》十翼阐发义理。六十四卦并非六十四种命运，而是六十四种「时势」——描述事物发展过程中的六十四类典型情境，供人参照自省。",
            bodyEn: "The I Ching builds from two line types — yin (broken) and yang (solid). Three lines form a trigram (eight in all: Heaven, Lake, Fire, Thunder, Wind, Water, Mountain, Earth); stacking two trigrams yields the 64 hexagrams. Each hexagram carries a Judgment text, each line its own statement, with the Ten Wings commentaries elaborating the philosophy. The 64 hexagrams are not 64 fates but 64 archetypal situations — configurations of circumstance offered as mirrors for reflection."),
        Topic(id: 2, icon: "circle.grid.2x2.fill",
            titleZh: "三枚铜钱起卦法与概率",
            titleEn: "The Three-Coin Method & Its Odds",
            bodyZh: "本 App 采用传统金钱卦：三枚铜钱掷一次得一爻，共掷六次，自下而上成卦。每次掷币：阳面记 3、阴面记 2，三枚之和为 6、7、8、9 之一——6 为老阴（阴极生阳，变爻）、7 为少阳、8 为少阴、9 为老阳（阳极生阴，变爻）。概率上：老阴与老阳各 1/8，少阳与少阴各 3/8。App 使用系统安全随机数模拟掷币，每一爻的生成过程与概率与实体铜钱完全一致。",
            bodyEn: "This app uses the traditional coin oracle: three coins per toss, six tosses, building the hexagram bottom-up. Heads counts 3, tails 2; each toss sums to 6, 7, 8, or 9 — 6 is old yin (changing), 7 young yang, 8 young yin, 9 old yang (changing). The odds: old lines 1/8 each, young lines 3/8 each. The app simulates tosses with the system's cryptographic random source, reproducing the physical coins' process and probabilities exactly."),
        Topic(id: 3, icon: "arrow.triangle.2.circlepath",
            titleZh: "变爻与变卦怎么看",
            titleEn: "Changing Lines & the Transformed Hexagram",
            bodyZh: "掷出老阳（9）或老阴（6）即为变爻——物极必反，老阳变阴、老阴变阳，全部变爻翻转后得到「变卦」。传统读法：本卦为当下之势，变卦为发展趋向。变爻的位置也有含义：初爻主开端，二爻主内部，三爻主临界，四爻主外部，五爻主主导（君位），上爻主终局。变爻多者，局势变数亦多，更宜守中观变。",
            bodyEn: "A toss of 9 (old yang) or 6 (old yin) makes a changing line — at its extreme, each polarity reverses. Flipping all changing lines yields the transformed hexagram. The traditional reading: the primary hexagram is the present configuration; the transformed one is the direction of development. Line positions carry meaning too — the first line governs beginnings, the second the interior, the third the threshold, the fourth the exterior, the fifth leadership, the top line endings. Many changing lines mean a volatile situation: hold the center and watch."),
        Topic(id: 4, icon: "hand.raised.fill",
            titleZh: "三不占（曾仕强）",
            titleEn: "The Three Don'ts of Divination",
            bodyZh: "曾仕强先生讲《易经》，反复强调占卜三原则：不诚不占——心不诚则卦不灵，起卦前当静心凝神；不义不占——违背道义之事不问卦，问了也不会有好答案；不疑不占——心中已有定见就不必占，占卜是为决疑，不是为了推卸决定的责任。这三条把占卜从迷信拉回修身：卦象是参考，决定权与责任始终在自己。",
            bodyEn: "Master Zeng Shiqiang, the noted I Ching lecturer, insisted on three principles: don't divine without sincerity — an unsettled mind receives no true answer; don't divine about unrighteous matters — improper questions have no good answers; don't divine when you're not genuinely in doubt — the oracle resolves uncertainty, it doesn't take responsibility off your shoulders. These three rules pull divination away from superstition toward self-cultivation: the hexagram advises, but the decision and its responsibility remain yours."),
        Topic(id: 6, icon: "leaf.fill",
            titleZh: "占前仪礼",
            titleEn: "The Etiquette of Divination",
            bodyZh: "古人问卦，先有仪而后有占。其要有六：一曰择静——寻一处安静无人之地，放下手头之事；二曰正坐——正身端坐，双手捧器，古人多面南而坐；三曰净手——以示郑重；四曰定心——心绪不宁时不占，缓一缓再来；五曰一事一占——问题想清楚，一次只问一件事；六曰不再三问——《蒙》卦辞曰「初筮告，再三渎，渎则不告」，同一件事反复占问是对占卜的亵渎，也是对自己判断力的逃避。本 App 的起卦仪式（静息、默念、按印）正是这套仪礼的现代化：仪式不是迷信，而是帮你把心沉下来——心定了，看卦象才看得清。",
            bodyEn: "The ancients prepared before they asked. Six essentials: find a quiet place and set your affairs aside; sit upright, cradling the instrument — traditionally facing south; clean your hands as a mark of respect; do not divine while agitated — let the heart settle first; ask one clear question at a time; and never ask the same question repeatedly — the hexagram Meng warns that 'the first casting answers; to ask again and again is to profane the oracle.' This app's casting ritual (stillness, silent focus, the seal) is a modern form of that etiquette. Ritual is not superstition: it settles the mind, and a settled mind reads the hexagram clearly."),
        Topic(id: 5, icon: "scalemass.fill",
            titleZh: "如何看待占卜结果",
            titleEn: "How to Read a Reading",
            bodyZh: "《易经》的本义是「君子居则观其象而玩其辞，动则观其变而玩其占」——它是一面镜子，不是一道判决。卦无绝对吉凶：吉卦提醒惜福防满，凶卦指点趋避之道，所谓「吉凶悔吝生乎动」。合理的用法：把卦象当作一个换位思考的视角，检视自己看不到的盲区；不合理的用法：把人生决定外包给卦象。本 App 的一切解读仅供参考与自省，不构成任何专业建议。",
            bodyEn: "The classic's own description of its use: contemplate the images and ponder the words in stillness; observe the changes and weigh the omens in action. It is a mirror, not a verdict. No hexagram is absolutely good or bad — auspicious ones warn against complacency, difficult ones map the way through. Use a reading as a borrowed perspective to examine your blind spots; never outsource a life decision to it. Everything in this app is offered for reflection only and constitutes no professional advice."),
    ]

    var body: some View {
        NavigationStack {
            List(topics) { topic in
                DisclosureGroup {
                    Text(Lang.choose(topic.bodyZh, topic.bodyEn, lang))
                        .font(.callout)
                        .lineSpacing(6)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } label: {
                    Label(Lang.choose(topic.titleZh, topic.titleEn, lang), systemImage: topic.icon)
                        .font(.body.weight(.medium))
                }
            }
            .navigationTitle(L10n.t("guide_title", lang))
        }
    }
}

#Preview {
    GuideView()
}
