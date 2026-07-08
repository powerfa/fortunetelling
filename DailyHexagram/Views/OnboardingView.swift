import SwiftUI

/// First-launch introduction: what the app is, how casting works, the
/// Three Don'ts, and the entertainment-only framing. Shown once.
struct OnboardingView: View {
    @AppStorage("appLanguage") private var lang = "zh"
    @AppStorage("onboardingSeen") private var onboardingSeen = false

    var body: some View {
        VStack(spacing: 0) {
            // Language first — everything below follows it live.
            Picker("", selection: $lang) {
                Text("简体").tag("zh")
                Text("繁體").tag("zht")
                Text("English").tag("en")
            }
            .pickerStyle(.segmented)
            .frame(width: 240)
            .padding(.top, 24)

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Text("䷀")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.accentColor)
                        Text(L10n.t("ob_title", lang))
                            .font(.system(.largeTitle, design: .serif).bold())
                        Text(L10n.t("ob_intro", lang))
                            .font(.system(.callout, design: .serif))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 30)

                    VStack(alignment: .leading, spacing: 22) {
                        row("circle.grid.cross.fill",
                            L10n.t("ob_cast_title", lang), L10n.t("ob_cast_body", lang))
                        row("hand.raised.fill",
                            L10n.t("ob_sincere_title", lang), L10n.t("ob_sincere_body", lang))
                        row("sparkles",
                            L10n.t("ob_more_title", lang), L10n.t("ob_more_body", lang))
                    }
                    .padding(.horizontal, 28)

                    Text(L10n.t("ob_note", lang))
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 16)
            }

            Button {
                onboardingSeen = true
            } label: {
                Text(L10n.t("ob_start", lang))
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .interactiveDismissDisabled()
    }

    private func row(_ icon: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(body)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
