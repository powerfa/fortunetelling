import SwiftUI
import UIKit
import UserNotifications

/// 上香：长按香炉点香或一键上香（30福币），三炷心香随真实时间燃烧，
/// 青烟袅袅；燃尽时提醒（在后台则本地推送）。
struct IncenseView: View {
    @EnvironmentObject private var incense: IncenseStore
    @EnvironmentObject private var coins: CoinStore
    @AppStorage("appLanguage") private var lang = "zh"

    @State private var showConfirm = false
    @State private var showStore = false
    @State private var showDone = false
    @State private var doneBlessing: (zh: String, en: String) = IncenseView.blessings[0]

    /// 燃尽禅语
    static let blessings: [(zh: String, en: String)] = [
        ("一炷清香，万虑俱静。", "One stick of incense; ten thousand worries fall still."),
        ("心诚则灵，念念相续。", "Sincerity reaches far; intention carries on."),
        ("香烟袅处，心愿已达。", "Where the smoke curls, the wish has been carried."),
        ("静水流深，福自绵长。", "Still waters run deep; blessings run long."),
        ("守得云开，自见月明。", "Wait for the clouds to part, and the moon shows itself."),
        ("行善积德，香火有继。", "Kind deeds accumulate; the flame never dies."),
        ("万事随缘，心安即福。", "Let things follow their course; a settled heart is the blessing."),
        ("愿君所求，皆得如愿。", "May all that you seek come to be."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Text(L10n.t("incense_subtitle", lang))
                        .font(.system(.footnote, design: .serif))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)

                    scene
                        .frame(width: 340)

                    statusArea

                    Button {
                        attemptLight()
                    } label: {
                        HStack(spacing: 6) {
                            Image("CoinIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                            Text(L10n.t("incense_button", lang))
                                .font(.body.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(incense.isBurning)
                    .padding(.horizontal, 24)

                    Text(String(format: L10n.t("incense_count", lang), incense.totalCount))
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L10n.t("tab_incense", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showStore = true
                    } label: {
                        HStack(spacing: 5) {
                            Image("CoinIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                            Text("\(coins.balance)")
                                .font(.subheadline.bold())
                        }
                    }
                }
            }
            .sheet(isPresented: $showStore) {
                StoreView()
            }
            .alert(L10n.t("incense_confirm_title", lang), isPresented: $showConfirm) {
                Button(L10n.t("light_action", lang)) { light() }
                Button(L10n.t("cancel", lang), role: .cancel) {}
            } message: {
                Text(L10n.t("incense_confirm_msg", lang))
            }
            .alert(L10n.t("incense_done_title", lang), isPresented: $showDone) {
                Button(L10n.t("done", lang), role: .cancel) {}
            } message: {
                Text(lang == "zh" ? doneBlessing.zh : doneBlessing.en)
            }
            .task(id: incense.burningStart) {
                guard incense.isBurning else { return }
                while incense.isBurning {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    if incense.isBurning && incense.remaining() <= 0 {
                        complete()
                        break
                    }
                }
            }
            .onAppear {
                if incense.pendingCompletion {
                    incense.pendingCompletion = false
                    doneBlessing = Self.blessings.randomElement() ?? Self.blessings[0]
                    showDone = true
                }
                if incense.isBurning {
                    IncenseMusicPlayer.shared.startIfNeeded(remaining: incense.remaining())
                }
            }
        }
    }

    // MARK: - Scene

    /// Stick geometry pixel-measured on the artwork (1.png), unit coords.
    /// The sticks live in a separate sprite so they can genuinely shorten.
    /// Sprite is displayed vertically stretched 1.3x (anchored at the bowl) so the
    /// fresh sticks stand taller; painted sticks are plain strokes, so the
    /// stretch is invisible. Tips move up accordingly.
    static let stickTips: [CGPoint] = [
        CGPoint(x: 0.4576, y: 0.2837),
        CGPoint(x: 0.5037, y: 0.2837),
        CGPoint(x: 0.5488, y: 0.2837),
    ]
    static let stickBases: [CGPoint] = [
        CGPoint(x: 0.4806, y: 0.6443),
        CGPoint(x: 0.4991, y: 0.6443),
        CGPoint(x: 0.5202, y: 0.6443),
    ]
    static let spriteRect = CGRect(x: 0.4494, y: 0.2766, width: 0.1068, height: 0.3698)
    /// The fire stops at the ash surface, inside the bowl — never onto the near rim.
    static let burnEndY: CGFloat = 0.640
    static var burnFraction: CGFloat { (burnEndY - spriteRect.minY) / spriteRect.height }

    /// Stick x (unit) at a given unit y — each stick leans at its own angle.
    static func stickXUnit(atY y: CGFloat, stick i: Int) -> CGFloat {
        let tip = stickTips[i], base = stickBases[i]
        let t = min(1, max(0, (y - tip.y) / (base.y - tip.y)))
        return tip.x + (base.x - tip.x) * t
    }

    /// Points on the shared burn line (mask cut), used by ash caps, embers and smoke.
    static func burnPoints(progress: Double, in size: CGSize) -> [CGPoint] {
        let unitY = spriteRect.minY + (burnEndY - spriteRect.minY) * progress
        return (0..<3).map { i in
            CGPoint(x: stickXUnit(atY: unitY, stick: i) * size.width,
                    y: unitY * size.height)
        }
    }

    private var scene: some View {
        // Single base plate (sticks removed) + dynamic stick sprite + smoke/ember.
        // Mask, ash caps, embers and smoke all share ONE continuous burn line,
        // driven by a single high-rate timeline — no per-second jumps.
        Image("IncenseBase")
            .resizable()
            .scaledToFit()
            .overlay {
                GeometryReader { geo in
                    let rect = CGRect(x: Self.spriteRect.minX * geo.size.width,
                                      y: Self.spriteRect.minY * geo.size.height,
                                      width: Self.spriteRect.width * geo.size.width,
                                      height: Self.spriteRect.height * geo.size.height)
                    ZStack {
                        if let start = incense.burningStart {
                            TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                                let t = timeline.date.timeIntervalSinceReferenceDate
                                let p = min(1, max(0, timeline.date.timeIntervalSince(start) / IncenseStore.duration))
                                let points = Self.burnPoints(progress: p, in: geo.size)
                                let stickW = geo.size.width * 0.0085

                                ZStack {
                                    // sticks, cut at the burn line
                                    Image("IncenseSticks")
                                        .resizable()
                                        .frame(width: rect.width, height: rect.height)
                                        .mask(alignment: .bottom) {
                                            Rectangle()
                                                .frame(height: max(0, rect.height * (1 - p * Self.burnFraction)))
                                        }
                                        .position(x: rect.midX, y: rect.midY)
                                    // per-stick: ash cap above the cut, ember at the cut,
                                    // and a growth→drop ash cycle (stateless, time-driven)
                                    ForEach(points.indices, id: \.self) { i in
                                        let pt = points[i]
                                        let pulse = 0.6 + 0.4 * sin(t * 2.4 + Double(i) * 2.1)
                                        // stick direction (px) for tilt-aligned placement
                                        let dx = (Self.stickBases[i].x - Self.stickTips[i].x) * geo.size.width
                                        let dy = (Self.stickBases[i].y - Self.stickTips[i].y) * geo.size.height
                                        let len = sqrt(dx*dx + dy*dy)
                                        let ux = dx / len, uy = dy / len
                                        let tiltDeg = atan2(dx, dy) * 180 / .pi
                                        // ash growth→drop cycle, anchored to the moment of lighting:
                                        // no ash at t=0, and the ash column never exceeds
                                        // the length of stick actually consumed since the last drop.
                                        let tBurn = timeline.date.timeIntervalSince(start)
                                        let cycle = 18.0 + Double(i) * 6.0
                                        let tIn = tBurn.truncatingRemainder(dividingBy: cycle)
                                        let consumedSinceDrop = CGFloat(tIn / IncenseStore.duration) * rect.height
                                        let capH = min(stickW * (0.3 + 2.0 * tIn / cycle),
                                                       consumedSinceDrop + stickW * 0.3)
                                        // 香灰帽: sits above the cut, along the stick axis
                                        Capsule()
                                            .fill(
                                                LinearGradient(colors: [Color(red: 0.84, green: 0.82, blue: 0.78),
                                                                        Color(red: 0.60, green: 0.58, blue: 0.54)],
                                                               startPoint: .top, endPoint: .bottom)
                                            )
                                            .frame(width: stickW * 1.15, height: max(stickW * 0.3, capH))
                                            .rotationEffect(.degrees(tiltDeg))
                                            .position(x: pt.x - ux * (capH * 0.45),
                                                      y: pt.y - uy * (capH * 0.45))
                                        // 余烬 (glowing line at the burn front)
                                        Circle()
                                            .fill(Color(red: 1.0, green: 0.42, blue: 0.12))
                                            .frame(width: stickW * 1.4, height: stickW * 1.4)
                                            .blur(radius: stickW * 0.35)
                                            .shadow(color: Color(red: 1.0, green: 0.5, blue: 0.1).opacity(0.85 * pulse),
                                                    radius: stickW * 1.5)
                                            .opacity(0.45 + 0.55 * pulse)
                                            .position(x: pt.x + ux * stickW * 0.3,
                                                      y: pt.y + uy * stickW * 0.3)
                                        // 落灰: the broken-off cap falls into the bowl —
                                        // only after at least one full growth cycle has passed.
                                        if tIn < 0.9 && tBurn >= cycle {
                                            let fall = tIn / 0.9
                                            let ashY = 0.641 * geo.size.height
                                            Capsule()
                                                .fill(Color(red: 0.72, green: 0.70, blue: 0.66))
                                                .frame(width: stickW * 0.9, height: stickW * 1.7)
                                                .rotationEffect(.degrees(tiltDeg + fall * 100 * (i == 1 ? -1 : 1)))
                                                .position(x: pt.x + CGFloat(sin(fall * 3.1)) * stickW * 0.8,
                                                          y: pt.y + CGFloat(fall * fall) * (ashY - pt.y))
                                                .opacity(1 - fall * fall)
                                        }
                                    }
                                }
                            }
                            IncenseSmokeView(geoSize: geo.size,
                                             start: start,
                                             duration: IncenseStore.duration)
                                .transition(.opacity)
                                .allowsHitTesting(false)
                        } else {
                            // idle: full sticks
                            Image("IncenseSticks")
                                .resizable()
                                .frame(width: rect.width, height: rect.height)
                                .position(x: rect.midX, y: rect.midY)
                        }
                    }
                    .animation(.easeInOut(duration: 1.0), value: incense.isBurning)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 8, y: 3)
            .onLongPressGesture(minimumDuration: 0.6) {
                attemptLight()
            }
    }

    @ViewBuilder
    private var statusArea: some View {
        if incense.isBurning {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                Text(String(format: L10n.t("incense_burning", lang), timeString(incense.remaining(at: timeline.date))))
                    .font(.system(.callout, design: .serif))
                    .foregroundStyle(Color.accentColor)
            }
        } else {
            Text(L10n.t("incense_hint", lang))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t.rounded())
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    // MARK: - Actions

    private func attemptLight() {
        guard !incense.isBurning else { return }
        if coins.balance >= IncenseStore.cost {
            showConfirm = true
        } else {
            showStore = true
        }
    }

    private func light() {
        guard coins.spend(IncenseStore.cost) else { return }
        incense.light()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        IncenseMusicPlayer.shared.startIfNeeded(remaining: IncenseStore.duration)
        scheduleNotification()
    }

    private func complete() {
        IncenseMusicPlayer.shared.stop()
        incense.finish()
        doneBlessing = Self.blessings.randomElement() ?? Self.blessings[0]
        SoundPlayer.shared.playReveal()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showDone = true
    }

    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        let zh = lang == "zh"
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = zh ? "香已上完" : "The incense has burned out"
            content.body = zh ? "一炷心香燃尽，愿所求皆如愿。" : "Your incense offering is complete. May your wish be granted."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: IncenseStore.duration, repeats: false)
            center.add(UNNotificationRequest(identifier: "incenseDone", content: content, trigger: trigger))
        }
    }
}

// MARK: - Smoke (青烟袅袅: blurred particles with dual-frequency sway)

struct IncenseSmokeView: View {
    let geoSize: CGSize
    let start: Date
    let duration: TimeInterval

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let p = min(1, max(0, timeline.date.timeIntervalSince(start) / duration))
                let origins = IncenseView.burnPoints(progress: p, in: size)
                ctx.addFilter(.blur(radius: 4.5))
                for (oi, o) in origins.enumerated() {
                    // wide soft plume
                    drawPlume(ctx: ctx, t: t, origin: o, seedBase: Double(oi) * 17.3,
                              count: 12, rise: size.height * 0.34,
                              baseR: 3.2, growR: 9,
                              color: Color(red: 0.55, green: 0.57, blue: 0.60), alphaMax: 0.18)
                    // narrow brighter core
                    drawPlume(ctx: ctx, t: t, origin: o, seedBase: Double(oi) * 31.7 + 5,
                              count: 8, rise: size.height * 0.26,
                              baseR: 1.4, growR: 3.5,
                              color: Color(red: 0.80, green: 0.82, blue: 0.84), alphaMax: 0.28)
                }
            }
        }
    }

    private func drawPlume(ctx: GraphicsContext, t: Double, origin: CGPoint, seedBase: Double,
                           count: Int, rise: CGFloat, baseR: CGFloat, growR: CGFloat,
                           color: Color, alphaMax: Double) {
        for i in 0..<count {
            let seed = seedBase + Double(i) * 2.39
            let cycle = 5.5 + seed.truncatingRemainder(dividingBy: 2.4)
            let prog = (t / cycle + seed).truncatingRemainder(dividingBy: 1)
            let y = origin.y - CGFloat(prog) * rise
            let sway = sin(prog * 2 * .pi * 1.4 + seed) * 12 * prog
                     + sin(prog * 2 * .pi * 3.3 + seed * 2.2) * 5 * prog
            let x = origin.x + CGFloat(sway)
            let r = baseR + CGFloat(prog) * growR
            // fade in fast, fade out toward top
            let alpha = alphaMax * (1 - prog) * min(1, prog * 10)
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)),
                     with: .color(color.opacity(alpha)))
        }
    }
}

#Preview {
    IncenseView()
        .environmentObject(IncenseStore())
        .environmentObject(CoinStore())
        .environmentObject(StoreManager())
}
