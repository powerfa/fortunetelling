import SwiftUI

/// 祈福：请符 → 写心愿 → 挂上樱花许愿树（每日焕新，花瓣纷落）。
struct BlessingView: View {
    @EnvironmentObject private var blessing: BlessingStore
    @EnvironmentObject private var coins: CoinStore
    @AppStorage("appLanguage") private var lang = "zh"
    @State private var composing: CharmType? = nil
    @State private var showStore = false
    @State private var selectedCharm: HungCharm? = nil

    // Wind: random gusts gently sway the branch and the hanging charms.
    @State private var branchSway: Double = 0
    @State private var gustID = 0
    @State private var gustStrength: Double = 0

    /// Charm anchor points along the painted branch, measured on the cropped
    /// artwork (941×1254). Six large tags, filled center-out.
    private static let slots: [CGPoint] = [
        CGPoint(x: 0.543, y: 0.510),
        CGPoint(x: 0.674, y: 0.429),
        CGPoint(x: 0.413, y: 0.631),
        CGPoint(x: 0.804, y: 0.339),
        CGPoint(x: 0.283, y: 0.712),
        CGPoint(x: 0.935, y: 0.247),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Text(L10n.t("blessing_subtitle", lang))
                        .font(.system(.footnote, design: .serif))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)

                    sakuraScene
                        .frame(width: 310)

                    // --- charm shop (请符) ---
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Text(L10n.t("charm_shop", lang))
                                .font(.headline)
                                .foregroundStyle(Color.accentColor)
                            if blessing.isFreeAvailableToday && !blessing.isFull {
                                Text(L10n.t("free_today_badge", lang))
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.green.opacity(0.15)))
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(CharmType.catalog) { type in
                                    charmCard(type)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    if blessing.isFull {
                        Text(L10n.t("tree_full", lang))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Text(L10n.t("blessed_note", lang))
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L10n.t("tab_blessing", lang))
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
            .sheet(item: $composing) { type in
                WishComposeView(type: type)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showStore) {
                StoreView()
            }
            .alert(
                selectedCharm.map { CharmType.type(for: $0.typeId).name(lang) } ?? "",
                isPresented: Binding(get: { selectedCharm != nil }, set: { if !$0 { selectedCharm = nil } })
            ) {
                Button(L10n.t("done", lang), role: .cancel) { selectedCharm = nil }
            } message: {
                Text(selectedCharm.map { $0.wish.isEmpty ? CharmType.type(for: $0.typeId).bless(lang) : $0.wish } ?? "")
            }
            .onAppear {
                blessing.load()   // 每日焕新
            }
            .task { await windLoop() }
        }
    }

    /// Random gusts: every 6–14s the branch leans about half a degree and the
    /// charms answer with a small damped swing. Cancelled when the tab hides.
    private func windLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64.random(in: 6_000_000_000...14_000_000_000))
            guard !Task.isCancelled else { return }
            // Strength varies widely gust to gust: mostly faint breaths,
            // occasionally a slightly firmer puff.
            let strength = Double.random(in: 0.25...1.0)
            gustStrength = strength
            gustID &+= 1
            let lean = Double.random(in: 0.45...0.8) * strength
            withAnimation(.easeInOut(duration: Double.random(in: 0.9...1.4))) { branchSway = -lean }
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            withAnimation(.easeInOut(duration: Double.random(in: 1.1...1.6))) { branchSway = lean * 0.5 }
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            withAnimation(.easeInOut(duration: 1.7)) { branchSway = 0 }
        }
    }

    // MARK: - Scene: sky + sakura tree + falling petals + charms

    private var sakuraScene: some View {
        // Two layers: static paper background, and the branch layer (with the
        // charms riding on it) that alone sways in the wind around its base
        // at the top-right, where the bough enters the frame.
        Image("SakuraTree")   // inpainted paper + calligraphy, no branch
            .resizable()
            .scaledToFit()
            .overlay {
                Image("SakuraBranch")   // transparent branch/flower layer
                    .resizable()
                    .scaledToFit()
                    .overlay {
                        GeometryReader { geo in
                            ZStack {
                                ForEach(blessing.charms) { charm in
                                    let slot = Self.slots[charm.slot % Self.slots.count]
                                    HangingCharmView(
                                        charm: charm,
                                        isNew: charm.id == blessing.lastHungID,
                                        anchor: CGPoint(x: slot.x * geo.size.width,
                                                        y: slot.y * geo.size.height),
                                        tagSize: geo.size.width * 0.12,
                                        gustID: gustID,
                                        gustStrength: gustStrength
                                    )
                                    .onTapGesture { selectedCharm = charm }
                                }
                            }
                        }
                    }
                    .rotationEffect(.degrees(branchSway), anchor: UnitPoint(x: 0.97, y: 0.20))
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 8, y: 3)
    }

    private func charmCard(_ type: CharmType) -> some View {
        Button {
            guard !blessing.isFull else { return }
            if blessing.isFreeAvailableToday || coins.balance >= type.price {
                composing = type
            } else {
                showStore = true
            }
        } label: {
            VStack(spacing: 5) {
                CharmTag(type: type, size: 30)
                Text(type.name(lang))
                    .font(.footnote.bold())
                    .foregroundStyle(.primary)
                HStack(spacing: 4) {
                    Image("CoinIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                    Text("\(type.price)")
                        .font(.footnote.bold())
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(8)
            .frame(width: 104)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            .opacity(blessing.isFull ? 0.5 : 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Charm tag (原画风格成品资源: 麻绳+黄铜环+回纹描边+墨书+朱印)

struct CharmTag: View {
    let type: CharmType
    var size: CGFloat = 52   // plaque width in pt

    /// Asset geometry: canvas 114 x 304, plaque width 102 within the canvas.
    static let canvasOverPlaque: CGFloat = 114.0 / 102.0
    static let aspect: CGFloat = 304.0 / 114.0
    /// Total on-screen height for a given plaque width.
    static func totalHeight(for size: CGFloat) -> CGFloat {
        size * canvasOverPlaque * aspect
    }

    var body: some View {
        Image("charm_\(type.id)")
            .resizable()
            .scaledToFit()
            .frame(width: size * Self.canvasOverPlaque)
    }
}

// MARK: - Hanging animation

struct HangingCharmView: View {
    let charm: HungCharm
    let isNew: Bool
    let anchor: CGPoint      // branch point: the cord hangs from here
    var tagSize: CGFloat = 38
    var gustID: Int = 0
    var gustStrength: Double = 0

    @State private var placed = false
    @State private var swing: Double = 0

    var body: some View {
        let totalH = CharmTag.totalHeight(for: tagSize)
        CharmTag(type: CharmType.type(for: charm.typeId), size: tagSize)
            .rotationEffect(.degrees(swing), anchor: .top)
            .position(x: anchor.x,
                      y: placed ? anchor.y + totalH / 2 : anchor.y + totalH / 2 + 320)
            .opacity(placed ? 1 : 0.2)
            .onAppear {
                guard isNew else {
                    placed = true
                    return
                }
                withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                    placed = true
                }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 620_000_000)
                    withAnimation(.easeInOut(duration: 0.24)) { swing = -9 }
                    try? await Task.sleep(nanoseconds: 240_000_000)
                    withAnimation(.easeInOut(duration: 0.24)) { swing = 6 }
                    try? await Task.sleep(nanoseconds: 240_000_000)
                    withAnimation(.easeInOut(duration: 0.22)) { swing = -3 }
                    try? await Task.sleep(nanoseconds: 220_000_000)
                    withAnimation(.easeInOut(duration: 0.35)) { swing = 0 }
                }
            }
            .onChange(of: gustID) { _, _ in
                windSwing()
            }
    }

    /// Small damped pendulum response to a gust. Charms further right start
    /// later (the gust travels across the branch); amplitude and timing get a
    /// touch of per-charm randomness so they never move in lockstep.
    private func windSwing() {
        Task { @MainActor in
            let delay = Double(anchor.x) * 0.0012 + Double.random(in: 0...0.15)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            let a = gustStrength * Double.random(in: 3.0...4.5)
            withAnimation(.easeInOut(duration: 0.55)) { swing = -a }
            try? await Task.sleep(nanoseconds: 550_000_000)
            withAnimation(.easeInOut(duration: 0.60)) { swing = a * 0.55 }
            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.easeInOut(duration: 0.60)) { swing = -a * 0.25 }
            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.easeInOut(duration: 0.70)) { swing = 0 }
        }
    }
}

// MARK: - Wish composing (写心愿)

struct WishComposeView: View {
    let type: CharmType
    @EnvironmentObject private var blessing: BlessingStore
    @EnvironmentObject private var coins: CoinStore
    @AppStorage("appLanguage") private var lang = "zh"
    @Environment(\.dismiss) private var dismiss
    @State private var wish = ""
    @FocusState private var focused: Bool

    private let maxChars = 40

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                CharmTag(type: type, size: 48)
                    .padding(.top, 4)
                VStack(spacing: 3) {
                    Text(type.name(lang))
                        .font(.title3.bold())
                    Text(type.bless(lang))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                TextField(L10n.t("wish_placeholder", lang), text: $wish, axis: .vertical)
                    .focused($focused)
                    .lineLimit(3, reservesSpace: true)
                    .font(.system(.body, design: .serif))
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .onChange(of: wish) { _, newValue in
                        if newValue.count > maxChars {
                            wish = String(newValue.prefix(maxChars))
                        }
                    }

                Text("\(wish.count)/\(maxChars)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button {
                    confirm()
                } label: {
                    HStack(spacing: 6) {
                        if blessing.isFreeAvailableToday {
                            Text("\(L10n.t("free_label", lang)) · \(L10n.t("hang_on_tree", lang))")
                                .font(.body.bold())
                        } else {
                            Image("CoinIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                            Text("\(type.price) · \(L10n.t("hang_on_tree", lang))")
                                .font(.body.bold())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(wish.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .navigationTitle(L10n.t("write_wish", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.t("cancel", lang)) { dismiss() }
                }
            }
            .onAppear { focused = true }
        }
    }

    private func confirm() {
        if blessing.isFreeAvailableToday {
            blessing.markFreeUsed()
        } else {
            guard coins.spend(type.price) else { return }
        }
        blessing.hang(type: type, wish: wish)
        SoundPlayer.shared.playReveal()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

#Preview {
    BlessingView()
        .environmentObject(BlessingStore())
        .environmentObject(CoinStore())
        .environmentObject(StoreManager())
}
