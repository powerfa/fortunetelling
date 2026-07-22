import SwiftUI
import UIKit

/// 起卦仪式：入静（三次呼吸）→ 凝神默念 → 朱印承诺 → 进入掷币。
/// 全程暗色如入静室；右上角可跳过。
struct CastRitualView: View {
    let question: String
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var lang = "zh"

    private enum Stage { case breathing, focus, seal }
    @State private var stage: Stage = .breathing
    @State private var breathScale: CGFloat = 0.55
    @State private var breathText = ""
    @State private var sealPressing = false
    @State private var sealProgress: CGFloat = 0
    @State private var sealed = false
    @State private var visible = false   // 整体淡入淡出
    @State private var ritualTask: Task<Void, Never>? = nil

    /// 占前小语：每次仪式随机一条（经典仪礼与民俗传统）。
    private static let hints: [(zh: String, en: String)] = [
        ("一事一占，所问愈明，所答愈明", "One question per casting — the clearer the asking, the clearer the answer"),
        ("《易》曰：初筮告，再三渎——同一事，不再三问", "Ask once: asking the same thing again and again clouds the answer"),
        ("心绪不宁时，且缓一缓再占", "If the heart is unsettled, let it settle before you cast"),
        ("择一静处，放下手头之事", "Find a quiet corner and set your tasks aside"),
        ("正身端坐，双手捧机，如捧三钱", "Sit upright, cradling the phone like three coins in your palms"),
        ("占前净手，以示郑重", "Clean hands before the asking, as a mark of respect"),
        ("古人占卜，多面南而坐", "The ancients often faced south to divine"),
        ("晨起心最静，是问卦的好时辰", "The quiet of early morning suits the asking best"),
    ]
    @State private var hint = CastRitualView.hints.randomElement()!

    private let ink = Color(red: 0.08, green: 0.07, blue: 0.10)
    private let glow = Color(red: 0.87, green: 0.72, blue: 0.37)
    private let seal = Color(red: 0.72, green: 0.16, blue: 0.12)

    var body: some View {
        ZStack {
            // 静室：墨色底 + 一点烛光式微光
            RadialGradient(colors: [ink.opacity(0.92), ink],
                           center: .center, startRadius: 40, endRadius: 420)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button(L10n.t("ritual_skip", lang)) {
                        finish()
                    }
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding()
                }
                Spacer()
            }

            switch stage {
            case .breathing: breathingStage
            case .focus:     focusStage
            case .seal:      sealStage
            }
        }
        .opacity(visible ? 1 : 0)
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) { visible = true }
            SoundPlayer.shared.playQing()
            ritualTask = Task { await runSequence() }
        }
        .onDisappear { ritualTask?.cancel() }
    }

    // MARK: - Stage 1 入静

    private var breathingStage: some View {
        VStack(spacing: 40) {
            Text(L10n.t("ritual_breathe", lang))
                .font(.system(.title3, design: .serif))
                .foregroundStyle(.white.opacity(0.85))
            ZStack {
                Circle()
                    .stroke(glow.opacity(0.25), lineWidth: 1)
                    .frame(width: 210, height: 210)
                Circle()
                    .fill(
                        RadialGradient(colors: [glow.opacity(0.35), glow.opacity(0.05)],
                                       center: .center, startRadius: 10, endRadius: 105)
                    )
                    .frame(width: 210, height: 210)
                    .scaleEffect(breathScale)
                Text(breathText)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.white.opacity(0.6))
            }
            // 占前小语：每次随机一条仪礼提示
            Text(Lang.choose(hint.zh, hint.en, lang))
                .font(.system(.footnote, design: .serif))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 44)
                .padding(.top, 6)
        }
        .transition(.opacity)
    }

    // MARK: - Stage 2 凝神

    private var focusStage: some View {
        VStack(spacing: 26) {
            Text(L10n.t("ritual_focus_hint", lang))
                .font(.system(.title3, design: .serif))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Text(question.isEmpty ? L10n.t("default_question", lang) : question)
                .font(.system(.title2, design: .serif).bold())
                .foregroundStyle(glow)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Text(L10n.t("ritual_tap_continue", lang))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .padding(.top, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            advanceToSeal()
        }
        .transition(.opacity)
    }

    // MARK: - Stage 3 朱印

    private var sealStage: some View {
        VStack(spacing: 36) {
            Text(L10n.t("ritual_seal_hint", lang))
                .font(.system(.title3, design: .serif))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            ZStack {
                // 按住时印章"蘸满印泥"：由黯淡渐转饱满朱红，红晕渐起
                Image("SealCheng")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                    .saturation(0.45 + 0.55 * Double(sealed ? 1 : sealProgress))
                    .opacity(0.72 + 0.28 * Double(sealed ? 1 : sealProgress))
                    .shadow(color: seal.opacity(sealed ? 0.8 : 0.15 + 0.35 * Double(sealProgress)),
                            radius: sealed ? 30 : 8 + 10 * sealProgress)
                // 金色描边随按压走一圈，与仪式的金光呼应
                RoundedRectangle(cornerRadius: 20)
                    .trim(from: 0, to: sealProgress)
                    .stroke(glow.opacity(0.85),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 144, height: 144)
                    .rotationEffect(.degrees(90))   // 从底部中点起笔
                    .opacity(sealed ? 0 : 1)        // 盖印后金线随红晕缓缓隐去
                    .animation(.easeOut(duration: 1.2), value: sealed)
            }
            .scaleEffect(sealed ? 0.92 : (sealPressing ? 0.97 : 1.0))
            .onLongPressGesture(minimumDuration: 1.0) {
                stamp()
            } onPressingChanged: { pressing in
                guard !sealed else { return }   // 盖印已成，松手不再回退
                sealPressing = pressing
                withAnimation(.linear(duration: pressing ? 1.0 : 0.25)) {
                    sealProgress = pressing ? 1 : 0
                }
            }

            Text(sealed ? L10n.t("ritual_sealed", lang) : " ")
                .font(.system(.body, design: .serif))
                .foregroundStyle(glow)
        }
        .transition(.opacity)
    }

    // MARK: - Sequence

    private func runSequence() async {
        // 三次呼吸：吸3秒，呼3秒
        for _ in 0..<3 {
            guard !Task.isCancelled else { return }
            breathText = Lang.choose("吸", "in", lang)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.easeInOut(duration: 3.0)) { breathScale = 1.0 }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            breathText = Lang.choose("呼", "out", lang)
            withAnimation(.easeInOut(duration: 3.0)) { breathScale = 0.55 }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
        }
        guard !Task.isCancelled, stage == .breathing else { return }
        withAnimation(.easeInOut(duration: 0.6)) { stage = .focus }
        // 凝神最长 10 秒后自动进入朱印（也可轻点提前）
        try? await Task.sleep(nanoseconds: 10_000_000_000)
        guard !Task.isCancelled, stage == .focus else { return }
        advanceToSeal()
    }

    private func advanceToSeal() {
        guard stage == .focus else { return }
        withAnimation(.easeInOut(duration: 0.6)) { stage = .seal }
    }

    private func stamp() {
        guard !sealed else { return }
        sealed = true
        SoundPlayer.shared.playStamp()
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            finish()
        }
    }

    private func finish() {
        ritualTask?.cancel()
        SoundPlayer.shared.stopQing()   // 磬声随退出一同淡去
        onComplete()
        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.7)) { visible = false }
            try? await Task.sleep(nanoseconds: 750_000_000)
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) { dismiss() }
        }
    }
}

#Preview {
    CastRitualView(question: "事业发展", onComplete: {})
}
