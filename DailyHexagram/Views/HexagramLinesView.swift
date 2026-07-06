import SwiftUI

/// Draws hexagram lines bottom-to-top.
/// Pass `values` (6/7/8/9, with changing markers) or `plainLines` (0/1).
struct HexagramLinesView: View {
    var values: [Int] = []
    var plainLines: [Int]? = nil
    var placeholderCount: Int = 0
    var lineHeight: CGFloat = 12
    var spacing: CGFloat = 10

    private struct Row: Identifiable {
        let id: Int
        let isYang: Bool?    // nil = placeholder
        let isChanging: Bool
    }

    private var rows: [Row] {
        var result: [Row] = []
        if let plain = plainLines {
            for (i, v) in plain.enumerated() {
                result.append(Row(id: i, isYang: v == 1, isChanging: false))
            }
        } else {
            for (i, v) in values.enumerated() {
                result.append(Row(id: i, isYang: v == 7 || v == 9, isChanging: v == 6 || v == 9))
            }
            var i = result.count
            while i < placeholderCount {
                result.append(Row(id: i, isYang: nil, isChanging: false))
                i += 1
            }
        }
        return result.reversed()
    }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(rows) { row in
                HStack(spacing: 6) {
                    lineShape(row)
                    marker(row)
                        .frame(width: 16)
                }
            }
        }
    }

    @ViewBuilder
    private func lineShape(_ row: Row) -> some View {
        if let isYang = row.isYang {
            if isYang {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.accentColor)
                    .frame(height: lineHeight)
            } else {
                HStack(spacing: lineHeight + 6) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.accentColor)
                    RoundedRectangle(cornerRadius: 3).fill(Color.accentColor)
                }
                .frame(height: lineHeight)
            }
        } else {
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundStyle(.quaternary)
                .frame(height: lineHeight)
        }
    }

    @ViewBuilder
    private func marker(_ row: Row) -> some View {
        if row.isChanging, let isYang = row.isYang {
            // ○ marks old yang (9), ✕ marks old yin (6)
            Text(isYang ? "○" : "✕")
                .font(.footnote.bold())
                .foregroundStyle(Color.accentColor)
        } else {
            Text(" ")
                .font(.footnote)
        }
    }
}

#Preview {
    HexagramLinesView(values: [7, 8, 9, 6, 7, 8])
        .frame(width: 170)
        .padding()
}
