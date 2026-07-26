# BudgetBuddy 省钱搭子 (iOS)

[![CI](https://github.com/661zzy/BudgetBuddy-iOS/actions/workflows/ci.yml/badge.svg)](https://github.com/661zzy/BudgetBuddy-iOS/actions/workflows/ci.yml)
[![License: Apache 2.0 modified](https://img.shields.io/badge/License-Apache%202.0%20modified-blue.svg)](LICENSE)

专为学生设计的财商练习 App：互动故事里练消费决策，顺手记账，AI 搭子帮你复盘。
A financial-literacy practice app for students — decision-making stories, quick expense logging, and an AI buddy for spending reviews.

**📱 App Store（中国区）**: https://apps.apple.com/cn/app/id6785993334 （v1.1：支持 iPad + 应用内评分入口）
**🌐 Web 版**: https://budgetbuddy.cn · **🤖 Android**: https://budgetbuddy.cn/android/

| | |
|---|---|
| 语言/框架 | Swift 5 · SwiftUI · iOS 16+ · iPhone & iPad（竖屏） |
| 工程生成 | [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`project.yml` 是唯一事实源，`.xcodeproj` 不入库） |
| 后端 | 自建 PHP + MySQL（`https://budgetbuddy.cn/api.php?r=`，本仓库不含服务端代码/密钥） |
| 内容 | 25 个互动故事、认知图鉴、理财课程、省钱挑战（`Sources/*.json` + `Assets.xcassets` 场景图） |
| 双语 | 中文为源语言，`Sources/L10n.swift` + `content_en.json` 提供英文 |

## 构建

```bash
brew install xcodegen        # 或任意方式安装 XcodeGen
cd BudgetBuddy-iOS
xcodegen generate
open BudgetBuddy.xcodeproj   # 或用下面的命令行构建
```

命令行（模拟器）：

```bash
xcodebuild -project BudgetBuddy.xcodeproj -scheme BudgetBuddy \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath ~/cache/bb-dd clean build CODE_SIGNING_ALLOWED=NO
```

已知坑（血泪换来的）：

- 项目若放在 iCloud 同步目录，构建前先 `xattr -cr Sources Resources Assets.xcassets UITests project.yml`，并把 derivedData 指到 iCloud 之外，否则 codesign 报 "resource fork/detritus not allowed"。
- `xcodegen generate` 之后必须 **clean** build，否则 UITests-Runner 缺 CFBundleIdentifier。
- UI 测试点 Tab 一律用元素定位（见各套件的 `tapTab`）：iOS 26 SDK 下底边坐标点不到标签按钮，iPadOS 18+ 标签栏在顶部。

## 测试

`UITests/` 下按用途分套件：`V11SmokeUITests`（双端冒烟+评分跳转）、`GuestModeUITests`（App Store 5.1.1(v) 游客合规）、`StabilityFlowUITests`（三轮稳定性 soak）等。

```bash
xcodebuild -project BudgetBuddy.xcodeproj -scheme BudgetBuddy \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath ~/cache/bb-dd \
  -only-testing:BudgetBuddyUITests/V11SmokeUITests clean test CODE_SIGNING_ALLOWED=NO
```

会通关故事的套件（如 StabilityFlow）通过启动参数 `-bb.review.prompted.v1 YES` 预置"已提示过评分"，避免系统评分弹窗干扰自动化。

需要账号的测试（登录/云同步/记账总结）从环境变量读取演示账号凭据，仓库内不含任何密码：

```bash
export TEST_RUNNER_BB_REVIEW_PASSWORD=***   # 演示账号密码（维护者持有）
export TEST_RUNNER_BB_TEST_PASSWORD=***     # 本地测试账号（可选）
```

未设置时相关用例自动跳过（XCTSkip）或不参与登录，游客路径测试不受影响。

## 安全说明

- 仓库不含任何密钥或密码：AI/数据库密钥只存在于服务器端（`ai.local.php` / `db.local.php`），演示账号密码经环境变量注入且会定期轮换（历史提交中出现过的旧密码已作废）。
- 后端源码不在本仓库。

## License

BudgetBuddy Source-Available License 1.0 — based on Apache License 2.0 with
additional restrictions for hosted services, embedded commercial products,
commercial app distribution, and resale. This is not an OSI-approved
open-source license. See [LICENSE](LICENSE). Copyright 2026 Samuel Zhang.
