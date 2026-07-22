import SwiftUI
import UIKit

/// Interactive three-coin casting: tap (or shake the device) six times, one line per toss, bottom up.
struct CastView: View {
    @EnvironmentObject private var store: DailyStore
    @AppStorage("appLanguage") private var lang = "zh"
    @AppStorage("castRitualEnabled") private var ritualEnabled = true

    private enum Phase { case intro, tossing }
    @State private var phase: Phase = .intro
    @State private var showRitual = false
    @State private var showReveal = false

    @State private var values: [Int] = []
    @State private var lastCoins: [Bool] = []
    @State private var question: String = ""
    @State private var coinAngles: [Double] = [0, 0, 0]
    @State private var isTossing = false
    @FocusState private var questionFocused: Bool

    var body: some View {
        Group {
            if phase == .intro {
                introView
            } else {
                tossingView
            }
        }
        .fullScreenCover(isPresented: $showRitual) {
            CastRitualView(question: question.trimmingCharacters(in: .whitespaces)) {
                withAnimation { phase = .tossing }
            }
            .presentationBackground(.clear)
        }
        .fullScreenCover(isPresented: $showReveal) {
            RevealRitualView(values: values, question: question) {
                withAnimation(.easeInOut) {
                    store.save(values: values, question: question)
                }
            }
            .presentationBackground(.clear)
        }
    }

    /// Present a cover without the system slide — our views fade themselves.
    private func presentGently(_ flag: Binding<Bool>) {
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) { flag.wrappedValue = true }
    }

    /// 时辰问候：晨/午/夜各有其语。
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11:  return L10n.t("greeting_morning", lang)
        case 11..<17: return L10n.t("greeting_noon", lang)
        default:      return L10n.t("greeting_night", lang)
        }
    }

    // MARK: - 静前：写下所问，开启仪式

    private var introView: some View {
        VStack(spacing: 18) {
            Text(L10n.dateText(lang: lang))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(greeting)
                .font(.system(.title3, design: .serif))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // 曾仕强「三不占」原则
            Text(L10n.t("three_no", lang))
                .font(.system(.footnote, design: .serif))
                .foregroundStyle(Color.accentColor.opacity(0.8))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            TextField(L10n.t("question_placeholder", lang), text: $question, axis: .vertical)
                .focused($questionFocused)
                .font(.callout)
                .padding(10)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .submitLabel(.done)
                .onChange(of: question) { _, newValue in
                    if newValue.contains("\n") {
                        question = newValue.replacingOccurrences(of: "\n", with: "")
                        questionFocused = false
                    }
                }

            Spacer()

            VStack(spacing: 10) {
                Button {
                    questionFocused = false
                    if ritualEnabled {
                        presentGently($showRitual)
                    } else {
                        withAnimation { phase = .tossing }
                    }
                } label: {
                    Text(L10n.t("start_cast", lang))
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)

                if ritualEnabled {
                    Button {
                        questionFocused = false
                        withAnimation { phase = .tossing }
                    } label: {
                        Text(L10n.t("quick_cast", lang))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // MARK: - 掷币

    private var tossingView: some View {
        VStack(spacing: 18) {
            Text(L10n.dateText(lang: lang))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(L10n.t("cast_prompt", lang))
                .font(.system(.body, design: .serif))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            if !question.trimmingCharacters(in: .whitespaces).isEmpty {
                Text("\(L10n.t("question_label", lang))：\(question)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.horizontal)
            }

            HexagramLinesView(values: values, placeholderCount: 6)
                .frame(width: 170)
                .padding(.vertical, 6)

            VStack(spacing: 10) {
                if !lastCoins.isEmpty {
                    HStack(spacing: 14) {
                        ForEach(lastCoins.indices, id: \.self) { i in
                            CoinView(isHeads: lastCoins[i])
                                .rotation3DEffect(.degrees(coinAngles[i]), axis: (x: 1, y: 0, z: 0))
                        }
                    }
                    if !isTossing, let last = values.last {
                        Text(L10n.lineName(for: last, lang: lang))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .transition(.opacity)
                    } else {
                        Text(" ").font(.callout)
                    }
                }
            }
            .frame(minHeight: 84)

            Spacer()

            if values.count < 6 {
                VStack(spacing: 8) {
                    Button(action: toss) {
                        Text(L10n.t("toss_button", lang))
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isTossing)

                    Text(String(format: L10n.t("toss_progress", lang), values.count + 1))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(L10n.t("shake_hint", lang))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else {
                Button {
                    presentGently($showReveal)
                } label: {
                    Text(L10n.t("reveal_button", lang))
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isTossing)
            }
        }
        .padding()
        // Keyboard would otherwise compress the whole layout and push the
        // question field (top of the page) out of view behind the nav bar.
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
            if phase == .tossing && values.count < 6 && !isTossing {
                toss()
            }
        }
    }

    private func toss() {
        guard !isTossing else { return }
        questionFocused = false
        isTossing = true

        SoundPlayer.shared.playToss()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let result = DivinationEngine.toss()

        // First toss: show coins immediately so the flip is visible.
        if lastCoins.isEmpty {
            lastCoins = [true, true, true]
        }

        // Spin the coins (3 full flips, slight stagger per coin).
        for i in 0..<3 {
            withAnimation(.easeOut(duration: 0.7).delay(Double(i) * 0.06)) {
                coinAngles[i] += 1080
            }
        }

        // Swap in the real faces mid-flip (invisible at the 90° edge).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            lastCoins = result.coins
        }

        // Land: record the line, restore interactivity.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation(.spring(duration: 0.4)) {
                values.append(result.value)
                isTossing = false
            }
            if values.count == 6 {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else if result.value == 6 || result.value == 9 {
                // A changing line deserves a stronger thump.
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
    }
}

/// A stylized bronze coin. Heads = 阳 (3), tails = 阴 (2).
struct CoinView: View {
    let isHeads: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: isHeads
                            ? [Color(red: 0.87, green: 0.68, blue: 0.32), Color(red: 0.66, green: 0.46, blue: 0.16)]
                            : [Color(red: 0.55, green: 0.43, blue: 0.27), Color(red: 0.38, green: 0.29, blue: 0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Rectangle()
                .fill(Color(.systemGroupedBackground))
                .frame(width: 12, height: 12)
            Text(isHeads ? "陽" : "陰")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.9))
                .offset(y: 15)
        }
        .frame(width: 46, height: 46)
        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    CastView().environmentObject(DailyStore())
}
