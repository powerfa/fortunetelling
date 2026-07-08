# 每日一卦 / Daily Hexagram

一款基于《周易》六十四卦的 iOS 算命 App。每天可占卜一次运势。

## 功能

- **三枚铜钱起卦法**：掷币六次，自下而上成卦，支持老阴/老阳变爻，有变爻时显示变卦
- **问卦流程**：起卦前可输入所问之事，随卦象一同保存
- **三不占提示**（曾仕强）：不诚不占、不义不占、不疑不占
- **每日限一次**：当天起卦后结果保留，次日方可再占
- **经典原文**：卦辞 + 《象传》（大象）原文 + 英译 + 中英文现代白话解读 + 吉凶等级
- **会员订阅**：解锁每卦事业/爱情/财运/健康四维深度详批（每维三段式：卦象分析→具体建议→提醒宜忌，中文均 150+ 字），StoreKit 2 月度/年度
- **福币系统**：每日签到 +1 福币（会员 +2）；签到日历以红圈标记已签到日，可翻看历史月份；消耗 10 福币可重新起卦（每天限一次）；福币内购四档：$0.99=30币、$4.99=180币（省16%）、$19.99=800币（省24%）、$49.99=2500币（省39%），优惠比例由实际单价动态计算并在购买页显示
- **占卜历史**：全部卦象自动存档（一年内），随时回看验证
- **易经知识页**：卦的构成、铜钱法概率（老阴老阳各1/8、少阳少阴各3/8）、变爻规则、三不占、如何看待结果——过程透明，可信可查
- **结果分享**：一键分享卦象文本
- **上香**：铜鼎香炉场景，长按香炉或一键上香（10福币）；三炷心香按真实时长燃烧（30分钟，DEBUG构建1分钟），退出App继续计时，燃尽本地推送提醒；实时青烟动画（Canvas模糊粒子双频摆动）、香体渐短、香头明灭；燃尽赠一句禅语，累计上香次数；点香起播原创冥想音乐（72秒无缝循环，鼓风低音+颂钵+古筝拨弦），跟随系统静音键（静音时不出声），与用户自己的音乐混音不抢占，退后台暂停回前台自动续播，燃尽自动淡出，设置中可关
- **祈福许愿树**：福币请符（平安/健康/事业/学业/财运/姻缘六种，8-12币，**每日首符免费**），写下心愿后以弹簧+摆动动画挂上许愿树；树每日焕新，最多挂12枚；点击树上的符可回看心愿
- **起卦体验**：铜钱 3D 翻转动画 + 合成音效（可在设置关闭）+ 触觉反馈；**摇一摇手机**也能掷币
- **桌面小组件（会员专属）**：小/中两种尺寸展示今日卦象，未起卦提示去起卦，非会员显示解锁引导，每日零点自动刷新
- **中英双语**：设置中一键切换，所有内容均为双语（数据含 27 个双语字段）

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

设置页底部有"重置今日卦象"按钮，便于测试，上架前可删除。

---

An I Ching daily fortune app for iOS. Traditional three-coin casting (with changing lines and transformed hexagram), one reading per day, fully bilingual (中文/English) content and UI. Requires Xcode 16+. For entertainment only.
