import SwiftUI
import UIKit

/// 揭卦过场：墨色屏上，卦象符号如墨迹晕开（模糊渐聚、微缩落定），
/// 短磬一响，卦名与吉凶浮现，随后落入结果页。轻点可跳过。
struct RevealRitualView: View {
    let values: [Int]
    let question: String
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var lang = "zh"

    @State private var symbolShown = false
    @State private var nameShown = false
    @State private var ready = false     // 显现完毕，等待用户轻点
    @State private var finishing = false
    @State private var visible = false   // 整体淡入淡出，避免生硬切换

    private let ink = Color(red: 0.08, green: 0.07, blue: 0.10)
    private let gold = Color(red: 0.87, green: 0.72, blue: 0.37)

    private var hex: Hexagram {
        DivinationResult(values: values, dateString: DailyStore.todayString).primary
    }

    var body: some View {
        ZStack {
            RadialGradient(colors: [ink.opacity(0.92), ink],
                           center: .center, startRadius: 40, endRadius: 420)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Text(hex.symbol)
                    .font(.system(size: 118))
                    .foregroundStyle(gold)
                    .blur(radius: symbolShown ? 0 : 16)
                    .scaleEffect(symbolShown ? 1.0 : 1.22)
                    .opacity(symbolShown ? 1 : 0)
                    .shadow(color: gold.opacity(symbolShown ? 0.35 : 0), radius: 24)

                VStack(spacing: 10) {
                    Text(hex.name(lang))
                        .font(.system(.title2, design: .serif).bold())
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                    Text(hex.level(lang))
                        .font(.footnote.bold())
                        .foregroundStyle(gold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .overlay(Capsule().strokeBorder(gold.opacity(0.5), lineWidth: 1))
                }
                .opacity(nameShown ? 1 : 0)
                .offset(y: nameShown ? 0 : 10)

                // 静候用户：有心理准备了再轻点进入解读
                Text(L10n.t("ritual_tap_continue", lang))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(ready ? 0.38 : 0))
                    .padding(.top, 36)
            }
            .padding(.horizontal, 30)
        }
        .opacity(visible ? 1 : 0)
        .preferredColorScheme(.dark)
        .contentShape(Rectangle())
        .onTapGesture {
            if ready {
                finish()
            } else {
                // 未显现完就点：快进到显现完毕，仍等下一次轻点
                withAnimation(.easeOut(duration: 0.4)) {
                    symbolShown = true
                    nameShown = true
                }
                withAnimation(.easeInOut(duration: 0.5).delay(0.3)) { ready = true }
            }
        }
        .task { await run() }
    }

    private func run() async {
        withAnimation(.easeInOut(duration: 0.55)) { visible = true }
        try? await Task.sleep(nanoseconds: 650_000_000)
        guard !ready else { return }
        SoundPlayer.shared.playQingShort()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.easeOut(duration: 1.5)) { symbolShown = true }
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        guard !ready else { return }
        withAnimation(.easeOut(duration: 0.7)) { nameShown = true }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        withAnimation(.easeInOut(duration: 0.8)) { ready = true }
    }

    private func finish() {
        guard !finishing else { return }
        finishing = true
        SoundPlayer.shared.stopQingShort()   // 磬声随进入解读一同淡去
        onComplete()          // TodayTab switches to ResultView beneath the cover
        Task { @MainActor in
            // 墨色渐渐散去，结果页从黑中浮现（白天模式也不闪白）
            withAnimation(.easeInOut(duration: 0.9)) { visible = false }
            try? await Task.sleep(nanoseconds: 950_000_000)
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) { dismiss() }
        }
    }
}

#Preview {
    RevealRitualView(values: [7, 8, 7, 9, 8, 7], question: "", onComplete: {})
}
