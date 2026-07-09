import Foundation
import CloudKit

/// 邀请好友：基于 CloudKit 公共数据库，无自建后端。
///
/// 数据模型（公共库）：
/// - `InviteCode`  recordName = "invite-<码>"，字段 ownerUserID。
///   recordName 的唯一性天然防撞码。
/// - `Redemption`  recordName = "redeem-<兑换者用户ID>"，字段 code /
///   inviterUserID / inviterCredited(0|1)。recordName 唯一性保证
///   一个 iCloud 账号终身只能兑换一次，重装 App 也无法重复。
///
/// 上架前需在 CloudKit Dashboard：给 Redemption 的 inviterUserID、
/// inviterCredited 建 Queryable 索引，并把 schema 部署到 Production。
@MainActor
final class InviteManager: ObservableObject {
    static let reward = 20          // 双方各得
    static let maxInvites = 10     // 邀请人封顶（10 人 = 200 币）

    /// App Store 链接：在 App Store Connect 创建 App 后把数字 ID 填进来，
    /// 例如 "https://apps.apple.com/app/id6740000000"。留空则分享文案不带链接。
    static let appStoreURLString = ""

    /// Share text for the invite: code on its own line + download link (once configured).
    static func shareText(code: String, lang: String) -> String {
        var text = String(format: L10n.t("invite_share_text", lang), reward, code)
        if !appStoreURLString.isEmpty {
            text += "\n" + appStoreURLString
        }
        return text
    }

    @Published private(set) var myCode: String?
    @Published private(set) var redeemed: Bool
    @Published private(set) var creditedCount: Int
    @Published private(set) var iCloudAvailable = false
    @Published private(set) var busy = false
    /// L10n key of a message to show, plus an optional coin amount for formatting.
    @Published var message: (key: String, amount: Int)?

    private let codeKey = "inviteMyCode"
    private let redeemedKey = "inviteRedeemed"
    private let creditedKey = "inviteCreditedCount"

    private let container = CKContainer(identifier: "iCloud.com.dj.DailyHexagram")
    private var db: CKDatabase { container.publicCloudDatabase }

    init() {
        myCode = UserDefaults.standard.string(forKey: codeKey)
        redeemed = UserDefaults.standard.bool(forKey: redeemedKey)
        creditedCount = UserDefaults.standard.integer(forKey: creditedKey)
    }

    // MARK: - Availability

    func refreshAvailability() async {
        iCloudAvailable = (try? await container.accountStatus()) == .available
    }

    // MARK: - My invite code

    /// Create (once) and cache this user's invite code.
    func ensureCode() async {
        guard myCode == nil, !busy else { return }
        busy = true
        defer { busy = false }
        do {
            let me = try await container.userRecordID().recordName
            for _ in 0..<5 {
                let code = Self.randomCode()
                let record = CKRecord(recordType: "InviteCode",
                                      recordID: CKRecord.ID(recordName: "invite-\(code)"))
                record["ownerUserID"] = me
                do {
                    _ = try await db.save(record)
                    myCode = code
                    UserDefaults.standard.set(code, forKey: codeKey)
                    return
                } catch let error as CKError where error.code == .serverRecordChanged {
                    continue   // rare collision — try another code
                }
            }
        } catch {
            message = ("invite_error", 0)
        }
    }

    private static func randomCode() -> String {
        // No 0/O/1/I/L — unambiguous when read aloud or typed.
        let charset = Array("23456789ABCDEFGHJKMNPQRSTUVWXYZ")
        return String((0..<6).map { _ in charset.randomElement()! })
    }

    // MARK: - Redeeming a friend's code

    func redeem(_ rawCode: String, coins: CoinStore) async {
        guard !busy else { return }
        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else { return }
        if let mine = myCode, code == mine {
            message = ("invite_self", 0)
            return
        }
        busy = true
        defer { busy = false }
        do {
            let me = try await container.userRecordID().recordName
            // 0. Gift codes share this entry point — try them first.
            if await redeemGift(code: code, me: me, coins: coins) { return }
            // 1. The code must exist…
            let invite: CKRecord
            do {
                invite = try await db.record(for: CKRecord.ID(recordName: "invite-\(code)"))
            } catch let error as CKError where error.code == .unknownItem {
                message = ("invite_invalid", 0)
                return
            }
            // 2. …and not be my own (covers multi-device same account too).
            guard let owner = invite["ownerUserID"] as? String, owner != me else {
                message = ("invite_self", 0)
                return
            }
            // 3. One redemption per iCloud account, enforced by recordName uniqueness.
            let redemption = CKRecord(recordType: "Redemption",
                                      recordID: CKRecord.ID(recordName: "redeem-\(me)"))
            redemption["code"] = code
            redemption["inviterUserID"] = owner
            redemption["inviterCredited"] = 0
            do {
                _ = try await db.save(redemption)
            } catch let error as CKError where error.code == .serverRecordChanged {
                markRedeemed()
                message = ("invite_already", 0)
                return
            }
            coins.add(Self.reward)
            markRedeemed()
            message = ("invite_success", Self.reward)
        } catch {
            message = ("invite_error", 0)
        }
    }

    private func markRedeemed() {
        redeemed = true
        UserDefaults.standard.set(true, forKey: redeemedKey)
    }

    // MARK: - Gift codes (礼品码)

    /// Developer-issued codes, created by hand in the CloudKit Dashboard:
    /// `GiftCode` recordName = "gift-<码>", fields: amount (Int64),
    /// maxRedemptions (Int64, 0 = unlimited), redeemedCount (Int64),
    /// active (Int64 0|1), expiresAt (Date, optional).
    /// Each user may redeem each gift code once (`GiftRedemption` recordName
    /// uniqueness), independent of the one-time invite redemption.
    ///
    /// Returns true when the code was handled as a gift code (message set).
    private func redeemGift(code: String, me: String, coins: CoinStore) async -> Bool {
        let gift: CKRecord
        do {
            gift = try await db.record(for: CKRecord.ID(recordName: "gift-\(code)"))
        } catch let error as CKError where error.code == .unknownItem {
            return false   // not a gift code — fall through to the invite path
        } catch {
            message = ("invite_error", 0)
            return true
        }
        let amount = (gift["amount"] as? Int64).map(Int.init) ?? 0
        let active = (gift["active"] as? Int64) ?? 1
        let maxRedemptions = (gift["maxRedemptions"] as? Int64) ?? 0
        let count = (gift["redeemedCount"] as? Int64) ?? 0
        let expired = (gift["expiresAt"] as? Date).map { $0 < Date() } ?? false
        guard active == 1, amount > 0, !expired,
              maxRedemptions == 0 || count < maxRedemptions else {
            message = ("gift_unavailable", 0)
            return true
        }
        let redemption = CKRecord(recordType: "GiftRedemption",
                                  recordID: CKRecord.ID(recordName: "giftredeem-\(code)-\(me)"))
        redemption["code"] = code
        do {
            _ = try await db.save(redemption)
        } catch let error as CKError where error.code == .serverRecordChanged {
            message = ("gift_already", 0)
            return true
        } catch {
            message = ("invite_error", 0)
            return true
        }
        coins.add(amount)
        message = ("gift_success", amount)
        // Best-effort usage counter (optimistic save; a lost race only makes
        // the count lag slightly — quota is enforced on the next reads).
        gift["redeemedCount"] = count + 1
        _ = try? await db.save(gift)
        return true
    }

    // MARK: - Collecting inviter rewards

    /// Query uncredited redemptions of my code and credit them (capped).
    /// Safe to call on every launch; silent on any failure.
    func collectRewards(coins: CoinStore) async {
        await refreshAvailability()
        guard iCloudAvailable, creditedCount < Self.maxInvites else { return }
        do {
            let me = try await container.userRecordID().recordName
            let predicate = NSPredicate(format: "inviterUserID == %@ AND inviterCredited == 0", me)
            let query = CKQuery(recordType: "Redemption", predicate: predicate)
            let (results, _) = try await db.records(matching: query, resultsLimit: Self.maxInvites)
            var gained = 0
            for (_, result) in results {
                guard creditedCount < Self.maxInvites, let record = try? result.get() else { continue }
                record["inviterCredited"] = 1
                do {
                    // Default save policy compares change tags — if another of
                    // my devices credited this record first, this save fails
                    // and we skip it (no double payout).
                    _ = try await db.save(record)
                    coins.add(Self.reward)
                    creditedCount += 1
                    gained += Self.reward
                    UserDefaults.standard.set(creditedCount, forKey: creditedKey)
                } catch {
                    continue
                }
            }
            if gained > 0 {
                message = ("invite_reward_arrived", gained)
            }
        } catch {
            // Missing index / network issues: silently retry next launch.
        }
    }
}
