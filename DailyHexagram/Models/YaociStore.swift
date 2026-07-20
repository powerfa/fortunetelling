import Foundation

/// One line statement (爻辞): original text, modern Chinese reading, English.
struct YaoLine: Codable {
    let t: String   // 爻辞原文（简体源，繁体经 Lang 转换）
    let m: String   // 白话
    let e: String   // English

    func meaning(_ lang: String) -> String {
        Lang.choose(m, e, lang)
    }
    func original(_ lang: String) -> String {
        Lang.hant(t, lang)
    }
}

struct YaoEntry: Codable {
    let n: Int
    let lines: [YaoLine]      // bottom-to-top
    let extra: YaoLine?       // 用九 (hex 1) / 用六 (hex 2)
}

/// Loads the 386 line statements (64×6 + 用九/用六) from yaoci.json.
final class YaociStore {
    static let shared = YaociStore()

    private let byNumber: [Int: YaoEntry]

    private init() {
        guard let url = Bundle.main.url(forResource: "yaoci", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([YaoEntry].self, from: data),
              list.count == 64
        else {
            byNumber = [:]
            return
        }
        byNumber = Dictionary(uniqueKeysWithValues: list.map { ($0.n, $0) })
    }

    /// The statement for line `index` (0-based, bottom-up) of a hexagram.
    func line(hexagram number: Int, index: Int) -> YaoLine? {
        guard let entry = byNumber[number], entry.lines.indices.contains(index) else { return nil }
        return entry.lines[index]
    }

    /// 用九/用六 — read when all six lines of hexagram 1 or 2 are changing.
    func extra(hexagram number: Int) -> YaoLine? {
        byNumber[number]?.extra
    }
}
