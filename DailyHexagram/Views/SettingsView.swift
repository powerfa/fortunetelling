import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: DailyStore
    @EnvironmentObject private var incense: IncenseStore
    @AppStorage("appLanguage") private var lang = "zh"
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("incenseMusicEnabled") private var incenseMusicEnabled = true
    @AppStorage("castRitualEnabled") private var ritualEnabled = true
    @AppStorage("dailyReminderEnabled") private var reminderEnabled = false
    @AppStorage("dailyReminderMinutes") private var reminderMinutes = DailyReminder.defaultMinutes
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
                    Toggle(isOn: $ritualEnabled) {
                        Label(L10n.t("ritual_setting", lang), systemImage: "moon.stars.fill")
                    }
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
                    Toggle(isOn: $reminderEnabled) {
                        Label(L10n.t("daily_reminder", lang), systemImage: "bell.badge")
                    }
                    if reminderEnabled {
                        DatePicker(
                            L10n.t("reminder_time", lang),
                            selection: Binding(
                                get: {
                                    Calendar.current.date(
                                        bySettingHour: reminderMinutes / 60,
                                        minute: reminderMinutes % 60,
                                        second: 0, of: Date()) ?? Date()
                                },
                                set: { date in
                                    let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                                    reminderMinutes = (c.hour ?? 8) * 60 + (c.minute ?? 0)
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                } footer: {
                    Text(L10n.t("daily_reminder_note", lang))
                }
                .onChange(of: reminderEnabled) { _, _ in syncReminder() }
                .onChange(of: reminderMinutes) { _, _ in syncReminder() }
                .onChange(of: lang) { _, _ in syncReminder() }

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
    private func syncReminder() {
        DailyReminder.update(enabled: reminderEnabled, minutes: reminderMinutes, lang: lang)
    }

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
