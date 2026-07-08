import Foundation
import SwiftUI

/// A charm type available in the shop (请符).
struct CharmType: Identifiable {
    let id: String
    let nameZh: String
    let nameEn: String
    let blessZh: String
    let blessEn: String
    let glyph: String        // character shown on the hanging tag
    let price: Int           // 福币
    let color: Color

    func name(_ lang: String) -> String { lang == "zh" ? nameZh : nameEn }
    func bless(_ lang: String) -> String { lang == "zh" ? blessZh : blessEn }

    static let catalog: [CharmType] = [
        CharmType(id: "safety", nameZh: "平安符", nameEn: "Safety Charm",
                  blessZh: "出入平安，四季无虞", blessEn: "Safe passage through all seasons",
                  glyph: "安", price: 8, color: Color(red: 0.76, green: 0.23, blue: 0.18)),
        CharmType(id: "health", nameZh: "健康符", nameEn: "Health Charm",
                  blessZh: "身心康泰，百病不侵", blessEn: "Wellness of body and mind",
                  glyph: "康", price: 8, color: Color(red: 0.18, green: 0.49, blue: 0.31)),
        CharmType(id: "career", nameZh: "事业符", nameEn: "Career Charm",
                  blessZh: "步步高升，事有所成", blessEn: "Steady ascent, work fulfilled",
                  glyph: "业", price: 10, color: Color(red: 0.42, green: 0.30, blue: 0.58)),
        CharmType(id: "study", nameZh: "学业符", nameEn: "Study Charm",
                  blessZh: "文思泉涌，金榜题名", blessEn: "Clear mind, honored name",
                  glyph: "学", price: 10, color: Color(red: 0.17, green: 0.37, blue: 0.54)),
        CharmType(id: "wealth", nameZh: "财运符", nameEn: "Wealth Charm",
                  blessZh: "财源广进，仓廪充盈", blessEn: "Fortune flowing in abundance",
                  glyph: "财", price: 12, color: Color(red: 0.72, green: 0.53, blue: 0.04)),
        CharmType(id: "love", nameZh: "姻缘符", nameEn: "Love Charm",
                  blessZh: "良缘天成，两心相知", blessEn: "Destined hearts, mutual knowing",
                  glyph: "缘", price: 12, color: Color(red: 0.76, green: 0.09, blue: 0.36)),
    ]

    static func type(for id: String) -> CharmType {
        catalog.first { $0.id == id } ?? catalog[0]
    }
}

/// One charm hung on today's tree.
struct HungCharm: Codable, Identifiable, Equatable {
    let id: UUID
    let typeId: String
    let wish: String
    let slot: Int
    let dateString: String
}

/// The wish tree: resets daily — only today's charms survive a reload.
final class BlessingStore: ObservableObject {
    static let maxSlots = 6

    @Published private(set) var charms: [HungCharm] = []
    /// Transient: the charm that should play the hanging animation.
    @Published var lastHungID: UUID? = nil
    /// 每日首符免费
    @Published private(set) var freeUsedToday: Bool = false

    private let storageKey = "blessingTreeCharms"
    private let freeKey = "blessingFreeDate"

    init() {
        load()
    }

    var isFreeAvailableToday: Bool { !freeUsedToday }

    func markFreeUsed() {
        UserDefaults.standard.set(DailyStore.todayString, forKey: freeKey)
        freeUsedToday = true
    }

    /// Reload from disk, dropping anything not hung today (每日焕新).
    func load() {
        freeUsedToday = UserDefaults.standard.string(forKey: freeKey) == DailyStore.todayString
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let list = try? JSONDecoder().decode([HungCharm].self, from: data)
        else {
            charms = []
            return
        }
        let today = list.filter { $0.dateString == DailyStore.todayString }
        charms = today
        if today.count != list.count {
            persist()
        }
    }

    var isFull: Bool {
        charms.count >= Self.maxSlots
    }

    /// Hang a new charm on the first free slot. Coin deduction is the caller's job.
    @discardableResult
    func hang(type: CharmType, wish: String) -> HungCharm? {
        guard !isFull else { return nil }
        let used = Set(charms.map(\.slot))
        let slot = (0..<Self.maxSlots).first { !used.contains($0) } ?? 0
        let charm = HungCharm(id: UUID(), typeId: type.id,
                              wish: wish.trimmingCharacters(in: .whitespacesAndNewlines),
                              slot: slot, dateString: DailyStore.todayString)
        charms.append(charm)
        lastHungID = charm.id
        persist()
        return charm
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(charms) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
