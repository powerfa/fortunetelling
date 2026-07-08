import Foundation

/// One of the 64 hexagrams of the I Ching, with bilingual content.
struct Hexagram: Codable, Identifiable, Equatable {
    let number: Int
    let symbol: String       // Unicode hexagram character, e.g. ䷀
    let nameZh: String       // 泰
    let fullZh: String       // 地天泰
    let pinyin: String       // Tài
    let nameEn: String       // Peace
    let upperZh: String
    let lowerZh: String
    let upperEn: String
    let lowerEn: String
    let levelZh: String      // 大吉 / 吉 / 中平 / 需谨慎
    let levelEn: String
    let lines: [Int]         // bottom-to-top, 1 = yang, 0 = yin
    let guaciZh: String      // 卦辞原文
    let guaciEn: String      // English rendering of the judgment
    let xiangZh: String      // 《象传》原文
    let xiangEn: String
    let modernZh: String     // 现代白话解读
    let modernEn: String
    // Premium detail readings
    let careerZh: String
    let careerEn: String
    let loveZh: String
    let loveEn: String
    let wealthZh: String
    let wealthEn: String
    let healthZh: String
    let healthEn: String

    var id: Int { number }

    func name(_ lang: String) -> String {
        Lang.choose("第\(number)卦 · \(fullZh)", "Hexagram \(number) · \(nameEn) (\(pinyin))", lang)
    }
    func level(_ lang: String) -> String { Lang.choose(levelZh, levelEn, lang) }
    func modern(_ lang: String) -> String { Lang.choose(modernZh, modernEn, lang) }
    func trigrams(_ lang: String) -> String {
        Lang.choose("\(upperZh)上\(lowerZh)下", "\(upperEn) over \(lowerEn)", lang)
    }
    func career(_ lang: String) -> String { Lang.choose(careerZh, careerEn, lang) }
    func love(_ lang: String) -> String { Lang.choose(loveZh, loveEn, lang) }
    func wealth(_ lang: String) -> String { Lang.choose(wealthZh, wealthEn, lang) }
    func health(_ lang: String) -> String { Lang.choose(healthZh, healthEn, lang) }
    /// Classical texts shown in Chinese for all languages; converted for 繁體.
    func guaci(_ lang: String) -> String { Lang.hant(guaciZh, lang) }
    func xiang(_ lang: String) -> String { Lang.hant(xiangZh, lang) }
}

/// Loads and indexes the 64 hexagrams from the bundled JSON resource.
final class HexagramStore {
    static let shared = HexagramStore()

    let all: [Hexagram]
    private let byPattern: [String: Hexagram]

    private init() {
        guard let url = Bundle.main.url(forResource: "hexagrams", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([Hexagram].self, from: data),
              list.count == 64
        else {
            fatalError("hexagrams.json is missing or invalid")
        }
        all = list.sorted { $0.number < $1.number }
        byPattern = Dictionary(uniqueKeysWithValues: list.map { (Self.key($0.lines), $0) })
    }

    static func key(_ lines: [Int]) -> String {
        lines.map(String.init).joined()
    }

    func hexagram(for lines: [Int]) -> Hexagram {
        guard let hex = byPattern[Self.key(lines)] else {
            fatalError("No hexagram for pattern \(lines)")
        }
        return hex
    }
}
