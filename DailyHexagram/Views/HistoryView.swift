import SwiftUI

/// History: past readings, hung wish charms (with their wishes), and
/// completed incense offerings. Revisiting builds trust in the practice.
struct HistoryView: View {
    @EnvironmentObject private var store: DailyStore
    @EnvironmentObject private var blessing: BlessingStore
    @EnvironmentObject private var incense: IncenseStore
    @AppStorage("appLanguage") private var lang = "zh"
    @State private var segment = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $segment) {
                    Text(L10n.t("hist_seg_cast", lang)).tag(0)
                    Text(L10n.t("hist_seg_blessing", lang)).tag(1)
                    Text(L10n.t("hist_seg_incense", lang)).tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 6)
                .padding(.bottom, 8)

                switch segment {
                case 1:  blessingList
                case 2:  incenseList
                default: castList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L10n.t("history_title", lang))
        }
    }

    // MARK: - 卦象

    @ViewBuilder
    private var castList: some View {
        if store.history.isEmpty {
            emptyView("clock.arrow.circlepath", L10n.t("history_empty", lang))
        } else {
            List {
                Section {
                    ForEach(store.history, id: \.dateString) { result in
                        NavigationLink {
                            ResultView(result: result, isHistory: true)
                                .navigationTitle(result.dateString)
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            castRow(result)
                        }
                    }
                } footer: {
                    Text(L10n.t("history_hint", lang))
                }
            }
        }
    }

    private func castRow(_ result: DivinationResult) -> some View {
        let hex = result.primary
        return HStack(spacing: 12) {
            Text(hex.symbol)
                .font(.system(size: 30))
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(Lang.choose(hex.fullZh, hex.nameEn, lang))
                        .font(.body.bold())
                    Text(hex.level(lang))
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentColor.opacity(0.13)))
                        .foregroundStyle(Color.accentColor)
                }
                Text("\(result.dateString) · \(result.question ?? L10n.t("default_question", lang))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - 祈福

    @ViewBuilder
    private var blessingList: some View {
        if blessing.archive.isEmpty {
            emptyView("sparkles", L10n.t("blessing_history_empty", lang))
        } else {
            List {
                ForEach(blessing.archive) { charm in
                    blessingRow(charm)
                }
            }
        }
    }

    private func blessingRow(_ charm: HungCharm) -> some View {
        let type = CharmType.type(for: charm.typeId)
        return HStack(alignment: .top, spacing: 12) {
            Image("charm_\(type.id)")
                .resizable()
                .scaledToFit()
                .frame(height: 52)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(type.name(lang))
                        .font(.body.bold())
                    Text(charm.dateString)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Text(charm.wish.isEmpty ? type.bless(lang) : charm.wish)
                    .font(.system(.callout, design: .serif))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }

    // MARK: - 上香

    @ViewBuilder
    private var incenseList: some View {
        if incense.records.isEmpty {
            emptyView("flame", L10n.t("incense_history_empty", lang))
        } else {
            List {
                Section {
                    ForEach(incense.records) { record in
                        HStack(spacing: 12) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 26)
                            Text(Self.timestamp(record.date, lang: lang))
                                .font(.callout)
                            Spacer()
                        }
                    }
                } header: {
                    Text(String(format: L10n.t("incense_count", lang), incense.totalCount))
                }
            }
        }
    }

    // MARK: - Shared

    private func emptyView(_ icon: String, _ text: String) -> some View {
        ContentUnavailableView {
            Label(L10n.t("history_title", lang), systemImage: icon)
        } description: {
            Text(text)
        }
        .frame(maxHeight: .infinity)
    }

    private static let zhTime: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN")
        f.dateStyle = .medium; f.timeStyle = .short; return f
    }()
    private static let zhtTime: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_TW")
        f.dateStyle = .medium; f.timeStyle = .short; return f
    }()
    private static let enTime: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US")
        f.dateStyle = .medium; f.timeStyle = .short; return f
    }()

    static func timestamp(_ date: Date, lang: String) -> String {
        switch lang {
        case "zh":  return zhTime.string(from: date)
        case "zht": return zhtTime.string(from: date)
        default:    return enTime.string(from: date)
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(DailyStore())
        .environmentObject(BlessingStore())
        .environmentObject(IncenseStore())
}
