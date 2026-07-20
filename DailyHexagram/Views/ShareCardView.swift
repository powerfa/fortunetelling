import SwiftUI

/// 分享图卡：古风纸质卡片，随 App 语言渲染，经 ImageRenderer 导出为图片。
/// Self-contained (no environment objects) so ImageRenderer can draw it.
struct ShareCardView: View {
    let result: DivinationResult
    let lang: String

    private var hex: Hexagram { result.primary }

    private let paper = Color(red: 0.957, green: 0.925, blue: 0.851)
    private let paperDeep = Color(red: 0.925, green: 0.882, blue: 0.784)
    private let ink = Color(red: 0.24, green: 0.20, blue: 0.16)
    private let gold = Color(red: 0.62, green: 0.47, blue: 0.19)
    private let seal = Color(red: 0.72, green: 0.20, blue: 0.15)

    var body: some View {
        VStack(spacing: 14) {
            // 眉头：日期 + 印章式标题
            HStack {
                Text(result.dateString)
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(ink.opacity(0.55))
                Spacer()
                Text(Lang.choose("每日一卦", "Daily Hexagram", lang))
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 4).fill(seal))
            }

            Spacer(minLength: 2)

            Text(hex.symbol)
                .font(.system(size: 92))
                .foregroundStyle(gold)

            Text(hex.name(lang))
                .font(.system(size: 25, weight: .bold, design: .serif))
                .foregroundStyle(ink)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Text(hex.trigrams(lang))
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(ink.opacity(0.6))
                Text(hex.level(lang))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(seal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .overlay(Capsule().strokeBorder(seal.opacity(0.6), lineWidth: 1))
            }

            ornamentDivider

            VStack(spacing: 8) {
                Text(lang == "en" ? hex.guaciEn : hex.guaci(lang))
                    .font(.system(size: 17, design: .serif))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                Text(lang == "en"
                     ? hex.xiangEn
                     : "\(Lang.hant("象曰：", lang))\(hex.xiang(lang))")
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(ink.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 6)

            if let question = result.question, !question.isEmpty {
                Text("\(L10n.t("question_label", lang))：\(question)")
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(ink.opacity(0.55))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 2)

            ornamentDivider

            Text(L10n.t("disclaimer", lang))
                .font(.system(size: 10))
                .foregroundStyle(ink.opacity(0.4))
        }
        .padding(22)
        .frame(width: 360, height: 520)
        .background(
            LinearGradient(colors: [paper, paperDeep],
                           startPoint: .top, endPoint: .bottom)
        )
        .overlay(
            // 双线描边，古籍框感
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .strokeBorder(gold.opacity(0.85), lineWidth: 2)
                    .padding(8)
                RoundedRectangle(cornerRadius: 0)
                    .strokeBorder(gold.opacity(0.45), lineWidth: 1)
                    .padding(12)
            }
        )
    }

    private var ornamentDivider: some View {
        HStack(spacing: 8) {
            Rectangle().fill(gold.opacity(0.45)).frame(height: 1)
            Text("❖")
                .font(.system(size: 9))
                .foregroundStyle(gold.opacity(0.7))
            Rectangle().fill(gold.opacity(0.45)).frame(height: 1)
        }
        .padding(.horizontal, 18)
    }
}

#Preview {
    ShareCardView(
        result: DivinationResult(values: [7, 8, 7, 9, 8, 7],
                                 dateString: "2026-07-09",
                                 question: "事业发展"),
        lang: "zh"
    )
}
