import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: DailyStore
    @EnvironmentObject private var incense: IncenseStore
    @AppStorage("appLanguage") private var lang = "zh"
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("incenseMusicEnabled") private var incenseMusicEnabled = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.t("language", lang)) {
                    Picker(L10n.t("language", lang), selection: $lang) {
                        Text("简体").tag("zh")
                        Text("繁體").tag("zht")
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
                    Toggle(isOn: $incenseMusicEnabled) {
                        Label(L10n.t("incense_music", lang), systemImage: "music.note")
                    }
                    .onChange(of: incenseMusicEnabled) { _, on in
                        if on {
                            if incense.isBurning {
                                IncenseMusicPlayer.shared.startIfNeeded(remaining: incense.remaining())
                            }
                        } else {
                            IncenseMusicPlayer.shared.stop(fade: 0.8)
                        }
                    }
                }

                Section {
                    Text(L10n.t("about_text", lang))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Link(L10n.t("terms_of_use", lang), destination: LegalLinks.termsOfUse)
                    Link(L10n.t("privacy_policy", lang), destination: LegalLinks.privacyPolicy)
                } header: {
                    Text(L10n.t("about", lang))
                } footer: {
                    Text("\(L10n.t("version", lang)) \(Self.appVersion)")
                }

                #if DEBUG
                Section {
                    Button(role: .destructive) {
                        store.resetToday()
                        dismiss()
                    } label: {
                        Text(L10n.t("reset_today", lang))
                    }
                }
                #endif
            }
            .navigationTitle(L10n.t("settings", lang))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.t("done", lang)) { dismiss() }
                }
            }
        }
    }
}

extension SettingsView {
    static var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

#Preview {
    SettingsView()
        .environmentObject(DailyStore())
        .environmentObject(IncenseStore())
}
