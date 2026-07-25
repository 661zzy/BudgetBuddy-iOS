# 省钱搭子 BudgetBuddy — iOS (native SwiftUI)

Native SwiftUI iOS app for BudgetBuddy. It talks to the existing PHP/MySQL backend at `https://budgetbuddy.cn` and syncs with the web account state without using a WebView shell.

## Current Status

Build 7 is the App Store candidate baseline.

Latest verification on 2026-06-29:

- Swift source typecheck passed for iOS 16 simulator.
- `build-for-testing` passed on `iPhone 17 Pro` simulator.
- Account deletion contract fixed and verified: Profile -> `删除账号` now asks for `当前密码`, sends it to `POST /auth/delete`, and failed deletion keeps the local session.
- `StabilityFlowUITests/testColdStartFullFlowThreeRounds` passed on `iPhone 17 Pro` with 3 full cold-start rounds, 1 test, 0 failures, 990.909 seconds. Result bundle: `/tmp/bb-ui-result-delete-fix.xcresult`.
- Generic iOS device build passed with `CODE_SIGNING_ALLOWED=NO`.
- Built Info.plist contains `ITSAppUsesNonExemptEncryption = false`, bundle id `cn.budgetbuddy.BudgetBuddy`, version `1.0` build `7`.

Implemented in SwiftUI:

- Auth, onboarding, session restore
- 首页 / 记账 / 故事 / AI搭子 / 我的 tab shell
- 记账 + 消费反思 + 记账总结
- 互动故事, 认知图鉴, 理财课程, generated scene art
- 省钱挑战 with check-in feedback
- AI 搭子 via the PHP backend proxy
- 我的: nickname editing, data export/reset, diagnostics feedback, legal links, logout, account deletion with current-password confirmation
- App Store support: app icon, real privacy/terms text, update check, screenshots/UI tests

## Project Layout

```text
Sources/
  App.swift             @main + RootView
  Theme.swift           shared colors and view helpers
  Models.swift          Codable app_state passthrough models
  APIClient.swift       URLSession client for budgetbuddy.cn
  AppStore.swift        @MainActor ObservableObject app state
  AuthView.swift        login/register
  MainView.swift        tab shell, home, AI, profile
  TrackerView.swift     ledger, reflection sheet, summary
  StoryView.swift       story path, codex, lessons, game player
  ChallengesView.swift  savings challenges
  LegalView.swift       in-app privacy policy and terms
  FeedbackView.swift    diagnostics feedback screen
  UpdateChecker.swift   version.json update prompt model/view
Resources/              stories, lessons, codex, challenge JSON
Assets.xcassets/         app icon + story scene art
UITests/                 stability, scene-art, App Store screenshot tests
project.yml              XcodeGen source of truth
```

## Build And Test

```bash
cd "/Users/chenmingming/Documents/Claude code/BudgetBuddy-iOS"
/tmp/XcodeGen/.build/release/xcodegen generate
xcodebuild -project BudgetBuddy.xcodeproj -scheme BudgetBuddy \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Main one-device regression:

```bash
xcodebuild test -project BudgetBuddy.xcodeproj -scheme BudgetBuddy \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BudgetBuddyUITests/StabilityFlowUITests/testColdStartFullFlowThreeRounds \
  -resultBundlePath /tmp/bb-ui-result-delete-fix.xcresult
```

The regression writes run notes and screenshots to `/Users/chenmingming/Documents/Claude code/BudgetBuddy-iOS-TestScreenshots/stability-runs`.

## App Store Notes

See `APP-STORE-LISTING.md` and `iOS-LAUNCH-CHECKLIST.md` for the submission checklist, review notes, privacy labels, and screenshot order.

Known external blocker: `https://budgetbuddy.cn/privacy.html` and `https://budgetbuddy.cn/terms.html` must be live before App Review. The local `省钱搭子 4.6.zip` release already includes those files, `version.json`, and the native `POST /auth/delete` endpoint that requires the current password, but it still needs to be deployed to the server.

Current URL check: `https://budgetbuddy.cn/api.php?r=/health` returns 200, while `privacy.html`, `terms.html`, `version.json`, and `api.php?r=/ai/disclosure` still return 404. Deployment is blocked until valid server credentials or a refreshed BaoTa panel entrance are available for `/www/wwwroot/budgetbuddy.cn`.
