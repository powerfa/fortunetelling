import SwiftUI

struct ResultView: View {
    let result: DivinationResult
    var isHistory: Bool = false
    @EnvironmentObject private var dailyStore: DailyStore
    @EnvironmentObject private var coins: CoinStore
    @EnvironmentObject private var storeKit: StoreManager
    @AppStorage("appLanguage") private var lang = "zh"
    @State private var showStore = false
    @State private var showRecastAlert = false

    private var hex: Hexagram { result.primary }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text(isHistory ? result.dateString : L10n.dateText(lang: lang))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(L10n.t("question_label", lang))：\(result.question ?? L10n.t("default_question", lang))")
                    .font(.system(.callout, design: .serif))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 8) {
                    Text(hex.symbol)
                        .font(.system(size: 64))
                        .foregroundStyle(Color.accentColor)
                    Text(hex.name(lang))
                        .font(.system(.title2, design: .serif).bold())
                        .multilineTextAlignment(.center)
                    Text(hex.trigrams(lang))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    levelBadge
                }

                HexagramLinesView(values: result.values)
                    .frame(width: 160)

                card(L10n.t("judgment", lang)) {
                    Text(hex.guaci(lang))
                        .font(.system(.title3, design: .serif))
                        .lineSpacing(6)
                    if lang == "en" {
                        Text(hex.guaciEn)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    Divider()
                    Text("\(L10n.t("xiang", lang))：\(hex.xiang(lang))")
                        .font(.system(.callout, design: .serif))
                        .foregroundStyle(.secondary)
                        .lineSpacing(5)
                    if lang == "en" {
                        Text(hex.xiangEn)
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                            .lineSpacing(4)
                    }
                }

                card(L10n.t("interpretation", lang)) {
                    Text(hex.modern(lang))
                        .font(.body)
                        .lineSpacing(6)
                }

                if !result.changingIndexes.isEmpty {
                    card(L10n.t("changing_lines", lang)) {
                        Text(changingText)
                            .font(.body)
                            .lineSpacing(5)
                        if let t = result.transformed {
                            Divider()
                            transformedView(t)
                        }
                    }
                }

                premiumSection

                if !isHistory {
                    recastSection

                    ShareLink(item: shareText) {
                        Label(L10n.t("share", lang), systemImage: "square.and.arrow.up")
                            .font(.callout)
                    }
                }

                VStack(spacing: 4) {
                    if !isHistory {
                        Text(L10n.t("already_cast", lang))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Text(L10n.t("disclaimer", lang))
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showStore) {
            StoreView()
        }
        .alert(L10n.t("recast_confirm_title", lang), isPresented: $showRecastAlert) {
            Button(L10n.t("confirm", lang), role: .destructive) {
                if coins.spend(CoinStore.recastCost) {
                    withAnimation { dailyStore.startRecast() }
                }
            }
            Button(L10n.t("cancel", lang), role: .cancel) {}
        } message: {
            Text(L10n.t("recast_confirm_msg", lang))
        }
    }

    // MARK: - Share

    private var shareText: String {
        var lines: [String] = []
        if Lang.isChinese(lang) {
            lines.append(Lang.hant("【每日一卦】", lang) + result.dateString)
            lines.append("\(Lang.hant("所问：", lang))\(result.question ?? L10n.t("default_question", lang))")
            lines.append("\(hex.symbol) \(hex.name(lang)) · \(hex.level(lang))")
            lines.append("\(Lang.hant("卦辞：", lang))\(hex.guaci(lang))")
            lines.append("\(Lang.hant("象曰：", lang))\(hex.xiang(lang))")
            lines.append(hex.modern(lang))
            if let t = result.transformed {
                lines.append("\(Lang.hant("变卦：", lang))\(t.symbol) \(t.name(lang))")
            }
        } else {
            lines.append("[Daily Hexagram] \(result.dateString)")
            lines.append("Question: \(result.question ?? L10n.t("default_question", lang))")
            lines.append("\(hex.symbol) \(hex.name(lang)) · \(hex.level(lang))")
            lines.append("Judgment: \(hex.guaciEn)")
            lines.append(hex.modern(lang))
            if let t = result.transformed {
                lines.append("Transformed: \(t.symbol) \(t.name(lang))")
            }
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Premium detail readings

    @ViewBuilder
    private var premiumSection: some View {
        card(L10n.t("premium_section", lang)) {
            if storeKit.isPremium {
                VStack(alignment: .leading, spacing: 14) {
                    detailRow("briefcase.fill", L10n.t("career", lang), hex.career(lang))
                    Divider()
                    detailRow("heart.fill", L10n.t("love", lang), hex.love(lang))
                    Divider()
                    detailRow("dollarsign.circle.fill", L10n.t("wealth", lang), hex.wealth(lang))
                    Divider()
                    detailRow("leaf.fill", L10n.t("health", lang), hex.health(lang))
                }
            } else {
                VStack(spacing: 12) {
                    Label(L10n.t("unlock_premium", lang), systemImage: "lock.fill")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button {
                        showStore = true
                    } label: {
                        Label(L10n.t("go_premium", lang), systemImage: "crown.fill")
                            .font(.body.bold())
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func detailRow(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                Text(text)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - Paid recast (once per day, 10 coins)

    @ViewBuilder
    private var recastSection: some View {
        if dailyStore.recastUsedToday {
            Text(L10n.t("recast_used", lang))
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            VStack(spacing: 5) {
                Button {
                    if coins.balance >= CoinStore.recastCost {
                        showRecastAlert = true
                    } else {
                        showStore = true
                    }
                } label: {
                    Label(L10n.t("recast_button", lang), systemImage: "arrow.triangle.2.circlepath")
                        .font(.body.bold())
                }
                .buttonStyle(.bordered)
                if coins.balance < CoinStore.recastCost {
                    Text(L10n.t("recast_need_coins", lang))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var levelBadge: some View {
        Text(hex.level(lang))
            .font(.footnote.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.accentColor.opacity(0.15)))
            .foregroundStyle(Color.accentColor)
    }

    private var changingText: String {
        let items = result.changingIndexes.map {
            L10n.changingLineName(index: $0, value: result.values[$0], lang: lang)
        }
        let joined = items.joined(separator: Lang.isChinese(lang) ? "、" : ", ")
        return Lang.isChinese(lang)
            ? Lang.hant("变爻：\(joined)。爻动则势变，今日之势正在转化，参看变卦。", lang)
            : "Changing: \(joined). The situation is in motion — see the transformed hexagram below."
    }

    private func transformedView(_ t: Hexagram) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("future_hexagram", lang))
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Text(t.symbol)
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(t.name(lang))
                        .font(.body.bold())
                    Text(t.guaci(lang))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            Text(t.modern(lang))
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
