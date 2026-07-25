# 在 Xcode 里运行「省钱搭子」(给测试者)

本工程用 **XcodeGen** 管理（`project.yml` 生成 `.xcodeproj`），所以第一步要先生成工程文件。

## 1. 安装 XcodeGen（只需一次）
```bash
brew install xcodegen
```
（没有 Homebrew 就先装 brew；或见 github.com/yonaskolb/XcodeGen 的其它安装方式）

## 2. 生成并打开工程
```bash
cd BudgetBuddy-iOS
xcodegen generate
open BudgetBuddy.xcodeproj
```

## 3. 运行
- **模拟器（最简单，无需签名）**：Xcode 顶部选一个 iPhone 模拟器 → 按 `Cmd+R` 运行。
- **真机**：选中 `BudgetBuddy` target → **Signing & Capabilities** → Team 选你自己的 Apple ID（个人 Team 就行）→ 顶部选你的设备 → `Cmd+R`。

## 说明
- App 连的是**线上后端 `budgetbuddy.cn`**，注册 / 登录 / 邮箱验证码 / 短信验证码都走**真实生产环境**。
- 注册可用**邮箱**（收验证码邮件）或**中国手机号**（收验证码短信）。
- 也可以用现成的**演示账号**登录：`review@budgetbuddy.cn` / `***SCRUBBED***`（已有样例数据）。
- 测试完可在 **我的 → 删除账号** 清掉自己的测试账号。
- 版本：**v1.0 (build 9)**；最低系统 iOS 16。
