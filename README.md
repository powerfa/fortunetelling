# 每日一卦 / Daily Hexagram

一款基于《周易》六十四卦的 iOS 算命 App。每天可占卜一次运势。

## 功能

- **三枚铜钱起卦法**：掷币六次，自下而上成卦，支持老阴/老阳变爻，有变爻时显示变卦
- **问卦流程**：起卦前可输入所问之事，随卦象一同保存
- **三不占提示**（曾仕强）：不诚不占、不义不占、不疑不占
- **每日限一次**：当天起卦后结果保留，次日方可再占
- **经典原文**：卦辞 + 《象传》（大象）原文 + 英译 + 中英文现代白话解读 + 吉凶等级
- **会员订阅**：解锁每卦事业/爱情/财运/健康四维深度详批（每维三段式：卦象分析→具体建议→提醒宜忌，中文均 150+ 字），StoreKit 2 月度/年度
- **福币系统**：钱包与签到记录存 iCloud 键值存储——重装 App 不丢，同一 Apple ID 的多台设备自动同步；每日签到 +1 福币（会员 +2）；签到日历以红圈标记已签到日，可翻看历史月份；每日免费一卦，重新起卦不限次数（每次 10 福币）；福币内购四档：$0.99=30币、$4.99=180币（省16%）、$19.99=800币（省24%）、$49.99=2500币（省39%），优惠比例由实际单价动态计算并在购买页显示
- **占卜历史**：全部卦象自动存档（一年内），随时回看验证
- **易经知识页**：卦的构成、铜钱法概率（老阴老阳各1/8、少阳少阴各3/8）、变爻规则、三不占、如何看待结果——过程透明，可信可查
- **结果分享**：一键分享卦象文本
- **上香**：铜鼎香炉场景，长按香炉或一键上香（10福币）；三炷心香按真实时长燃烧（30分钟，DEBUG构建1分钟），退出App继续计时，燃尽本地推送提醒；实时青烟动画（Canvas模糊粒子双频摆动）、香体渐短、香头明灭；燃尽赠一句禅语，累计上香次数；点香起播原创冥想音乐（72秒无缝循环，鼓风低音+颂钵+古筝拨弦），跟随系统静音键（静音时不出声），与用户自己的音乐混音不抢占，退后台暂停回前台自动续播，燃尽自动淡出，设置中可关
- **祈福许愿树**：福币请符（平安/健康/事业/学业/财运/姻缘六种，8-12币，**每日首符免费**），写下心愿后以弹簧+摆动动画挂上许愿树；树每日焕新，最多挂12枚；点击树上的符可回看心愿
- **起卦体验**：铜钱 3D 翻转动画 + 合成音效（可在设置关闭）+ 触觉反馈；**摇一摇手机**也能掷币
- **桌面小组件（会员专属）**：小/中两种尺寸展示今日卦象，未起卦提示去起卦，非会员显示解锁引导，每日零点自动刷新
- **三语支持**：简体中文 / 繁體中文 / English，设置中一键切换。繁体由 ICU Hans-Hant 转换器从简体实时转换（带缓存），全部内容（64卦数据、界面、Widget、知识页、禅语、符名）自动覆盖，永不失步
- **完整历史**：历史页分三栏——卦象（可回看完整解读）、祈福（记录符种类与心愿原文）、上香（每次完成时间与累计次数）
- **iCloud 全量同步**：福币/签到、卦象历史与今日卦象、上香记录、许愿树与祈福档案、邀请状态全部经 iCloud 键值存储同步——重装不丢，同一 Apple ID 多设备一致；合并策略：历史按日期取最新、记录按 ID 并集、余额首次合并取大、今日卦象最后写入者胜（重算可跨设备传播）

## Widget 配置说明

工程含两个 target：主 App 与 `DailyHexagramWidget`（Widget Extension），通过 App Group `group.com.dj.DailyHexagram` 共享数据。

- 模拟器可直接运行（App Group 无需配置）
- 真机运行需在两个 target 的 Signing & Capabilities 中选择你的团队，并在开发者账号里注册该 App Group（或改成你自己的 group ID，同时修改 `WidgetBridge.swift` 和 `DailyHexagramWidget.swift` 中的 `appGroup` 常量）

## 内购测试

本地测试无需 App Store Connect：

1. Xcode 菜单 Product → Scheme → Edit Scheme → Run → Options
2. StoreKit Configuration 选择根目录的 `DailyHexagram.storekit`
3. 运行后即可测试订阅与买币；DEBUG 构建下商店页还有"开启会员"测试开关

上架时需在 App Store Connect 创建同 ID 的产品：
`com.dj.DailyHexagram.premium.monthly / .premium.yearly / .coins30 / .coins180 / .coins800 / .coins2500`

## 运行

1. 需要 **Xcode 16+**（工程使用文件夹同步格式）
2. 打开 `DailyHexagram.xcodeproj`
3. 选择模拟器或真机，⌘R 运行
4. 真机运行需在 Signing & Capabilities 里选择你的开发者账号

## 结构

```
DailyHexagram/
├── DailyHexagramApp.swift        # 入口
├── Models/
│   ├── Hexagram.swift            # 卦模型 + JSON 加载与卦形索引
│   ├── DivinationEngine.swift    # 三枚铜钱算法（6/7/8/9，变爻，变卦）
│   └── DailyStore.swift          # 每日一次限制（UserDefaults）
├── Localization/L10n.swift       # 双语 UI 字符串
├── Views/                        # 起卦、结果、设置界面
└── Resources/hexagrams.json      # 64卦双语数据（已程序化校验卦形映射）
```

"重置今日卦象"测试按钮与"测试开关会员"仅在 DEBUG 构建可见，Release/上架版本自动隐藏。

## 邀请好友（CloudKit，无自建后端）

商店页 → 邀请好友：好友输码后双方各得 20 福币，邀请人上限 10 人。基于 CloudKit 公共数据库：
`InviteCode`（recordName=`invite-<码>`）与 `Redemption`（recordName=`redeem-<兑换者用户ID>`，
天然保证一个 iCloud 账号终身只兑换一次，重装无效；自邀被 ownerUserID 校验拦截）。

- 需登录 iCloud；模拟器测试 CloudKit 不稳定，请用真机 + 两个 iCloud 账号测完整流程
- 首次运行后到 [CloudKit Dashboard](https://icloud.developer.apple.com) → 该容器 → Schema：
  给 `Redemption` 的 `inviterUserID` 添加 **Queryable** 索引（领奖查询需要）
- 记录类型共五个：`InviteCode` / `Redemption` / `RewardClaim`（邀请人领奖凭证，字段
  `redemption` String，公共库记录仅创建者可写，故领奖不改他人记录而是建自己的凭证）/
  `GiftCode` / `GiftRedemption`
- **上架前必须**在 Dashboard 把 Development schema **Deploy to Production**，否则线上全部报错

### 礼品码（与邀请码共用兑换入口）

在 CloudKit Dashboard 手工创建 `GiftCode` 记录即可发码（营销、补偿、KOL 等场景）：

1. Schema → Record Types 新建 `GiftCode` 类型，字段：`amount`(Int64 面额福币) ·
   `maxRedemptions`(Int64 总次数上限，0=不限) · `redeemedCount`(Int64 建0) ·
   `active`(Int64 1=启用 0=停用) · `expiresAt`(Date 可选)
2. Data → Records → Public Database 新建 `GiftCode` 记录：**Record Name 填 `gift-<码>`**
   （如 `gift-XINNIAN88`，用户输入 `XINNIAN88`，码必须全大写），其余字段按需填
- 每个用户每个礼品码只能兑换一次（`GiftRedemption` 记录唯一性保证），可兑换多个不同码
- 注意：`GiftCode`/`GiftRedemption` 两个记录类型需在 Development 环境先各建一条测试记录跑通，
  再随 schema 一起部署到 Production，线上创建的礼品码记录要建在 **Production** 环境

## 上架清单（App Store 提交前）

1. **隐私政策**：项目根目录的 `privacy.html` 需发布为公开网页（如 GitHub Pages），并保证与
   `StoreManager.swift` 里 `LegalLinks.privacyPolicy` 的 URL 一致（App Store Connect 也要填同一 URL）
2. **App 隐私问卷**：邀请功能在 CloudKit 存了用户ID与邀请关系 → 申报"标识符（用户ID）· 与用户关联 · 仅用于App功能"；无第三方SDK、无追踪，其余选"不收集"
3. **CloudKit**：Dashboard 索引 + schema 部署到 Production（见上节）
4. **订阅产品**：App Store Connect 创建上述产品 ID，订阅组内含月度/年度两档
5. **邀请分享链接**：在 App Store Connect 创建 App 记录后（无需等上线），到 App 信息页复制数字
   Apple ID，填入 `InviteManager.swift` 顶部的 `appStoreURLString`
   （格式 `https://apps.apple.com/app/id<数字>`），并重新打包——否则邀请分享文案不带下载链接
6. **购买页合规**：已内置恢复购买、自动续费说明、使用条款（Apple 标准 EULA）与隐私政策链接
7. **付费协议**：App Store Connect → 协议、税务和银行业务，签署 Paid Apps 协议并填银行/税务信息——不签内购产品无法生效
8. **出口合规**：提交时"加密"问题选"仅使用豁免的标准加密"（App 只用 HTTPS/系统加密）
9. **商店素材**：App 名称/副标题/描述/关键词（三语可分区本地化）、6.7" 与 6.5" 截图、年龄分级问卷（占卜类正常可 4+）
10. **订阅信息**：订阅组内两档产品需填显示名与描述；建议同时配置订阅推广图
11. **TestFlight 回归**：真机过一遍核心流程——起卦/重算/签到/买币/订阅/祈福/上香(30分钟版)/邀请双机流程/三语切换/Widget
12. **审核备注**：建议注明"占卜内容仅供娱乐（4.3/5.6 相关）；App 内已多处标注 for entertainment only"
13. **开发者署名**：如不想显示个人姓名，需以组织（公司）身份注册开发者账号

---

An I Ching daily fortune app for iOS. Traditional three-coin casting (with changing lines and transformed hexagram), one reading per day, fully bilingual (中文/English) content and UI. Requires Xcode 16+. For entertainment only.
