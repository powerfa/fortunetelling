import SwiftUI

/// Past readings — revisiting them against reality builds trust in the practice.
struct HistoryView: View {
    @EnvironmentObject private var store: DailyStore
    @AppStorage("appLanguage") private var lang = "zh"

    var body: some View {
        NavigationStack {
            Group {
                if store.history.isEmpty {
                    ContentUnavailableView {
                        Label(L10n.t("history_title", lang), systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text(L10n.t("history_empty", lang))
                    }
                } else {
                    List {
                        Section {
                            ForEach(store.history, id: \.dateString) { result in
                                NavigationLink {
                                    ResultView(result: result, isHistory: true)
                                        .navigationTitle(result.dateString)
                                        .navigationBarTitleDisplayMode(.inline)
                                } label: {
                                    historyRow(result)
                                }
                            }
                        } footer: {
                            Text(L10n.t("history_hint", lang))
                        }
                    }
                }
            }
            .navigationTitle(L10n.t("history_title", lang))
        }
    }

    private func historyRow(_ result: DivinationResult) -> some View {
        let hex = result.primary
        return HStack(spacing: 12) {
            Text(hex.symbol)
                .font(.system(size: 30))
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(lang == "zh" ? hex.fullZh : hex.nameEn)
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
}

#Preview {
    HistoryView().environmentObject(DailyStore())
}
