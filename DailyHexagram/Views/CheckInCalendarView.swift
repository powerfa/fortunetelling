import SwiftUI
import UIKit

/// A hand-drawn vermillion circle (朱笔画圈): one open brush stroke — it does
/// NOT close. The width swells and thins along the way (thin flick at the
/// start, blunt heavy end), with per-date wobble so each mark is unique.
struct HandDrawnCircle: Shape {
    /// `progress` ∈ 0...1 draws the stroke up to that fraction — the path is
    /// built incrementally, so the overlapping tail animates correctly.
    var progress: CGFloat = 1

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    /// 起笔在圆底中心略偏左（细尾），绕一整圈后**短短越过起笔约 22°**收笔。
    /// 尾段带显式的向下坠量：从起笔下方擦过、沿底部向左下自然收束。
    static let startAngle = 1.72
    static let sweep = 2 * Double.pi * 1.06

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX, cy = rect.midY
        let radius = min(rect.width, rect.height) / 2 * 0.88
        let start = Self.startAngle
        let totalSteps = 84
        let steps = max(2, Int(CGFloat(totalSteps) * min(max(progress, 0), 1)))
        var outer: [CGPoint] = []
        var inner: [CGPoint] = []
        for i in 0...steps {
            let t = Double(i) / Double(totalSteps)
            let angle = start + Self.sweep * t
            // 更圆：抖动减半，压扁减轻
            let wobble = 1
                + 0.028 * sin(2 * angle + 0.8)
                + 0.020 * sin(3 * angle + 2.3)
            // 尾段处理：轻微径向让开（留缝）+ 显式向下坠（收笔朝下）
            let u = min(1, max(0, (t - 0.86) / 0.14))
            let drift = 0.10 * pow(u, 1.1)
            let drop = radius * 0.34 * pow(u, 1.6)
            let rx = radius * (1.00 * wobble + drift)
            let ry = radius * (0.94 * wobble + drift)
            // 笔画宽度：细入 → 中段起伏 → 收笔加重后顿住
            var w = radius * 0.16
            w *= min(1, t / 0.10)
            w *= 1 + 0.20 * sin(5 * angle + 1.1)
                   + 0.07 * sin(23 * angle + 4.0)
            w *= (t > 0.85) ? (1 + 0.45 * (t - 0.85) / 0.15) : 1
            w = max(w, radius * 0.02)
            let half = CGFloat(w / 2)
            outer.append(CGPoint(x: cx + CGFloat(cos(angle)) * (rx + half),
                                 y: cy + CGFloat(sin(angle)) * (ry + half) + drop))
            inner.append(CGPoint(x: cx + CGFloat(cos(angle)) * (rx - half),
                                 y: cy + CGFloat(sin(angle)) * (ry - half) + drop))
        }
        var path = Path()
        path.move(to: outer[0])
        for p in outer.dropFirst() { path.addLine(to: p) }
        for p in inner.reversed() { path.addLine(to: p) }
        path.closeSubpath()
        return path
    }
}

/// Month calendar: tap TODAY's date to check in — a vermillion circle is
/// drawn around it by hand (trim animation + brush sound). Checked days keep
/// their hand-drawn marks.
struct CheckInCalendarView: View {
    let checkedDates: Set<String>
    var canCheckInToday: Bool = false
    var onCheckInToday: (() -> Void)? = nil
    @AppStorage("appLanguage") private var lang = "zh"
    @State private var monthOffset = 0   // 0 = current month, negative = earlier
    @State private var animatingKey: String? = nil
    @State private var drawProgress: CGFloat = 0

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

    /// 朱砂色 — a touch deeper than pure red, like seal ink.
    private static let vermillion = Color(red: 0.76, green: 0.17, blue: 0.12)

    private func dayCell(_ date: Date) -> some View {
        let key = Self.keyFormatter.string(from: date)
        let checked = checkedDates.contains(key)
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date() && !isToday
        let tappable = isToday && canCheckInToday && !checked
        return ZStack {
            if tappable {
                // 待签到的今日：淡淡的提示底色
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 30, height: 30)
            }
            if checked {
                HandDrawnCircle(progress: key == animatingKey ? drawProgress : 1)
                    .fill(Self.vermillion.opacity(0.88))
                    .frame(width: 32, height: 32)
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
        .contentShape(Rectangle())
        .onTapGesture {
            guard tappable else { return }
            checkInWithFlourish(key: key)
        }
    }

    /// 点今日日期：落笔音效 + 手写朱圈描画动画 + 触觉反馈。
    private func checkInWithFlourish(key: String) {
        SoundPlayer.shared.playBrush()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        animatingKey = key
        drawProgress = 0
        onCheckInToday?()   // store updates -> `checked` becomes true
        withAnimation(.easeInOut(duration: 1.25)) {
            drawProgress = 1
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

#Preview {
    CheckInCalendarView(checkedDates: [DailyStore.todayString])
        .padding()
}
