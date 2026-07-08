import SwiftUI

/// Month calendar: checked-in days are marked with a red circle (打卡红圈).
struct CheckInCalendarView: View {
    let checkedDates: Set<String>
    @AppStorage("appLanguage") private var lang = "zh"
    @State private var monthOffset = 0   // 0 = current month, negative = earlier

    // Cached calendars & formatters — rebuilding per render costs frames.
    private static let zhCalendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2   // 中文周一起
        return c
    }()
    private static let enCalendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 1   // 英文周日起
        return c
    }()

    private var calendar: Calendar {
        Lang.isChinese(lang) ? Self.zhCalendar : Self.enCalendar
    }

    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let zhMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月"
        return f
    }()
    private static let enMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private var displayedMonth: Date {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        return calendar.date(byAdding: .month, value: monthOffset, to: start)!
    }

    private var monthTitle: String {
        (Lang.isChinese(lang) ? Self.zhMonthFormatter : Self.enMonthFormatter).string(from: displayedMonth)
    }

    private var weekdaySymbols: [String] {
        Lang.isChinese(lang) ? ["一", "二", "三", "四", "五", "六", "日"]
                             : ["S", "M", "T", "W", "T", "F", "S"]
    }

    /// Leading nil-padding + one Date per day of the displayed month.
    private var cells: [Date?] {
        let first = displayedMonth
        guard let range = calendar.range(of: .day, in: .month, for: first) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: first)
        let lead = (firstWeekday - calendar.firstWeekday + 7) % 7
        var result: [Date?] = Array(repeating: nil, count: lead)
        for day in range {
            result.append(calendar.date(byAdding: .day, value: day - 1, to: first))
        }
        return result
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    monthOffset -= 1
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                Spacer()
                Text(monthTitle)
                    .font(.subheadline.bold())
                Spacer()
                Button {
                    monthOffset += 1
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)
                .disabled(monthOffset >= 0)
            }
            .foregroundStyle(Color.accentColor)

            // Deterministic (non-lazy) grid: LazyVGrid inside a Form row causes
            // UICollectionView self-sizing feedback loops and crashes.
            VStack(spacing: 6) {
                HStack(spacing: 0) {
                    ForEach(weekdaySymbols.indices, id: \.self) { i in
                        Text(weekdaySymbols[i])
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                ForEach(weekRows.indices, id: \.self) { r in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { c in
                            Group {
                                if let date = weekRows[r][c] {
                                    dayCell(date)
                                } else {
                                    Color.clear.frame(height: 32)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    /// Cells padded to full weeks and chunked into rows of 7.
    private var weekRows: [[Date?]] {
        var all = cells
        while all.count % 7 != 0 { all.append(nil) }
        return stride(from: 0, to: all.count, by: 7).map { Array(all[$0..<$0+7]) }
    }

    private func dayCell(_ date: Date) -> some View {
        let key = Self.keyFormatter.string(from: date)
        let checked = checkedDates.contains(key)
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date() && !isToday
        return ZStack {
            if checked {
                Circle()
                    .stroke(Color.red, lineWidth: 1.8)
                    .frame(width: 30, height: 30)
            }
            Text("\(calendar.component(.day, from: date))")
                .font(.callout)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(
                    isFuture ? Color.secondary.opacity(0.4)
                             : (isToday ? Color.accentColor : Color.primary)
                )
        }
        .frame(height: 32)
    }
}

#Preview {
    CheckInCalendarView(checkedDates: [DailyStore.todayString])
        .padding()
}
