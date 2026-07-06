import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: DailyStore
    @AppStorage("appLanguage") private var lang = "zh"
    @AppStorage("soundEnabled") private var soundEnabled = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.t("language", lang)) {
                    Picker(L10n.t("language", lang), selection: $lang) {
                        Text("中文").tag("zh")
                        Text("English").tag("en")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: lang) { _, newValue in
                        WidgetBridge.setLanguage(newValue)
                    }
                }

                Section {
                    Toggle(isOn: $soundEnabled) {
                        Label(L10n.t("sound", lang), systemImage: "speaker.wave.2.fill")
                    }
                }

                Section(L10n.t("about", lang)) {
                    Text(L10n.t("about_text", lang))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button(role: .destructive) {
                        store.resetToday()
                        dismiss()
                    } label: {
                        Text(L10n.t("reset_today", lang))
                    }
                }
            }
            .navigationTitle(L10n.t("settings", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.t("done", lang)) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView().environmentObject(DailyStore())
}
