import Foundation

/// Result of one full divination: six line values (bottom to top).
/// Values follow the traditional three-coin method:
/// 6 = old yin (changing), 7 = young yang, 8 = young yin, 9 = old yang (changing).
struct DivinationResult: Codable, Equatable {
    let values: [Int]
    let dateString: String
    var question: String? = nil   // 所问之事 (optional)
    /// Creation time (unix epoch). Used to resolve same-day conflicts when
    /// merging histories across devices; optional for backward compatibility.
    var epoch: Double? = nil

    /// The primary (本卦) hexagram lines: 1 = yang, 0 = yin.
    var primaryLines: [Int] {
        values.map { ($0 == 7 || $0 == 9) ? 1 : 0 }
    }

    /// Indexes (0-based, bottom to top) of the changing lines.
    var changingIndexes: [Int] {
        values.indices.filter { values[$0] == 6 || values[$0] == 9 }
    }

    /// The transformed (变卦) hexagram lines, if there are changing lines.
    var transformedLines: [Int]? {
        guard !changingIndexes.isEmpty else { return nil }
        return values.map { v in
            switch v {
            case 9: return 0   // old yang becomes yin
            case 6: return 1   // old yin becomes yang
            case 7: return 1
            default: return 0  // 8
            }
        }
    }

    var primary: Hexagram { HexagramStore.shared.hexagram(for: primaryLines) }
    var transformed: Hexagram? { transformedLines.map { HexagramStore.shared.hexagram(for: $0) } }
}

enum DivinationEngine {
    /// Toss three coins. Heads (阳面) = 3, tails (阴面) = 2. Sum is 6...9.
    static func toss() -> (coins: [Bool], value: Int) {
        let coins = (0..<3).map { _ in Bool.random() }
        let value = coins.map { $0 ? 3 : 2 }.reduce(0, +)
        return (coins, value)
    }
}
