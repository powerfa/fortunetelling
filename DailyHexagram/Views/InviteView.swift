import SwiftUI
import UIKit

/// 邀请好友：展示我的邀请码 + 分享，输入好友邀请码兑换。双方各得福币。
struct InviteView: View {
    @EnvironmentObject private var invite: InviteManager
    @EnvironmentObject private var coins: CoinStore
    @AppStorage("appLanguage") private var lang = "zh"
    @Environment(\.dismiss) private var dismiss
    @State private var codeInput = ""
    @State private var justCopied = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(String(format: L10n.t("invite_rule", lang),
                                InviteManager.reward, InviteManager.maxInvites))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !invite.iCloudAvailable {
                    Section {
                        Label(L10n.t("invite_need_icloud", lang), systemImage: "icloud.slash")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section(L10n.t("my_invite_code", lang)) {
                        if let code = invite.myCode {
                            HStack(spacing: 12) {
                                Text(code)
                                    .font(.system(.title2, design: .monospaced).bold())
                                    .foregroundStyle(Color.accentColor)
                                    .textSelection(.enabled)
                                Button {
                                    UIPasteboard.general.string = code
                                    justCopied = true
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    Task {
                                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                                        justCopied = false
                                    }
                                } label: {
                                    Label(L10n.t(justCopied ? "copied" : "copy", lang),
                                          systemImage: justCopied ? "checkmark" : "doc.on.doc")
                                        .font(.caption.bold())
                                }
                                .buttonStyle(.bordered)
                                .tint(justCopied ? .green : .accentColor)
                                Spacer()
                                ShareLink(item: InviteManager.shareText(code: code, lang: lang)) {
                                    Label(L10n.t("invite_share", lang), systemImage: "square.and.arrow.up")
                                        .font(.callout.bold())
                                }
                            }
                        } else if invite.busy {
                            ProgressView()
                        } else {
                            Button(L10n.t("invite_generate", lang)) {
                                Task { await invite.ensureCode() }
                            }
                        }
                        Text(String(format: L10n.t("invite_progress", lang),
                                    invite.creditedCount,
                                    invite.creditedCount * InviteManager.reward))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Section {
                        // Gift codes stay redeemable even after the one-time
                        // invite redemption, so the field is always visible.
                        HStack {
                            TextField(L10n.t("invite_code_placeholder", lang), text: $codeInput)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                            Button(L10n.t("redeem", lang)) {
                                Task {
                                    await invite.redeem(codeInput, coins: coins)
                                    if invite.message?.key.hasSuffix("success") == true {
                                        codeInput = ""
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(codeInput.trimmingCharacters(in: .whitespaces).count < 4
                                      || invite.busy)
                        }
                    } header: {
                        Text(L10n.t("enter_invite_code", lang))
                    } footer: {
                        if invite.redeemed {
                            Label(L10n.t("invite_redeemed", lang), systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .navigationTitle(L10n.t("invite_title", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.t("done", lang)) { dismiss() }
                }
            }
            .task {
                await invite.refreshAvailability()
                if invite.iCloudAvailable {
                    await invite.ensureCode()
                }
            }
            .alert(
                alertText,
                isPresented: Binding(
                    get: { invite.message != nil },
                    set: { if !$0 { invite.message = nil } }
                )
            ) {
                Button(L10n.t("ok", lang), role: .cancel) { invite.message = nil }
            }
        }
    }

    private var alertText: String {
        guard let m = invite.message else { return "" }
        let text = L10n.t(m.key, lang)
        return m.amount > 0 ? String(format: text, m.amount) : text
    }
}

#Preview {
    InviteView()
        .environmentObject(InviteManager())
        .environmentObject(CoinStore())
}
