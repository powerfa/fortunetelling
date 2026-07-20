# Roadmap（待实现功能计划）

## 1. 终身会员（一次性买断）

**目标**：吸收反感订阅的用户，提升总付费转化。买断档定价应显著高于年费（约 2.5–3 倍年费），
锚定"长期用户才划算"，避免蚕食订阅收入。

**产品设计**
- 产品 ID：`com.dj.DailyHexagram.premium.lifetime`，类型 **Non-Consumable**（非消耗型）
- 建议定价：$29.99（对照月度/年度定价调整，保持 ≈3×年费）
- 权益与订阅会员完全一致（四维详批、Widget、双倍签到）
- 购买页展示顺序：月度 → 年度 → 终身（终身标"一次购买，永久有效"角标）

**技术要点**
- `StoreManager.ProductID.all` 加入 lifetime；`refreshPremium()` 中
  `Transaction.currentEntitlements` 需同时认 `productType == .nonConsumable`
  且 ID 为 lifetime 的交易（非消耗型交易永久保留在 entitlements 里，无需额外存储）
- 恢复购买已有，天然支持买断恢复
- `.storekit` 测试配置加同 ID 产品本地验证；App Store Connect 建非消耗型商品
- 已是终身会员时，购买页隐藏两档订阅，显示「终身会员已开通」
- 边界：先订阅后买断（正常，entitlement 双持有）；订阅期内买断后引导用户自行取消订阅
  （加一行提示文案 + 打开订阅管理链接 `https://apps.apple.com/account/subscriptions`）

**工作量估计**：半天（含测试）。

## 2. 评分请求（SKStoreReviewController）

**目标**：上架初期积累评分，提升商店转化。Apple 限制每年最多向同一用户弹 3 次，
触发时机必须选在"用户刚获得正向体验"的瞬间。

**触发策略**
- 主触发：**第 3 次完成起卦**（查看结果页停留 2 秒后）——用户已建立使用习惯
- 备选触发：第 2 次上香燃尽的禅语弹窗关闭后（正向情绪峰值）
- 每个版本最多请求一次：记录 `lastReviewRequestVersion`，版本号变了才允许再次触发
- 永不在出错、支付、余额不足等负面场景后触发

**技术要点**
- iOS 18+ 用 `AppStore.requestReview(in:)`（StoreKit），iOS 17 用
  `SKStoreReviewController.requestReview(in:)`；工程 target iOS 17，可用
  `if #available(iOS 18.0, *)` 分支或直接用 SwiftUI 的 `@Environment(\.requestReview)`
  （iOS 16+，最简）
- 计数器存 UserDefaults：`castCompletedCount`，在 `DailyStore.save()` 后自增
- 实现位置：ResultView `.onAppear` 检查计数与版本标记，满足则延迟 2 秒请求
- 注意：系统自行决定是否真的弹窗（静默失败正常），不要在 UI 上承诺"去评分"

**工作量估计**：1–2 小时。

## 其他候选（未排期）

- 连续签到梯度奖励（连签7天+5币/30天+20币，日历显示连签数）
- 二十四节气与节日运营（节气祝语 + 节日礼品码活动）
- 六十四卦图鉴（知识页升级为可浏览卦典）
- 年度报告（占卦统计+分享图，年底自动生成）
- 香品扩展（不同香型时长/价格/音乐）
- 许愿树成长体系（累计挂符解锁树的形态变化）
- 邀请链接 Universal Link（点链接跳App自动填码，需自有域名）
