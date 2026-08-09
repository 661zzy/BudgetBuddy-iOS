import XCTest

// v1.3 记账总结 smoke: the 周/月 scope toggle exists, both scopes render their
// stat cards, and the AI advice section auto-loads (real reply or graceful
// fallback — never blank). Needs the review account; credentials come from env
// (BB_REVIEW_ACCOUNT / BB_REVIEW_PASSWORD) so nothing sensitive lives in code.
final class TrackerSummaryUITests: XCTestCase {
    private var app: XCUIApplication!
    private let account = ProcessInfo.processInfo.environment["BB_REVIEW_ACCOUNT"] ?? "review@budgetbuddy.cn"
    private let password = ProcessInfo.processInfo.environment["BB_REVIEW_PASSWORD"] ?? ""

    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipIf(password.isEmpty, "Set BB_REVIEW_PASSWORD to run account-based tests")
        app = XCUIApplication()
        app.launchArguments += ["-bb.engage.prompted.v1", "YES"]   // keep the 3-min engagement sheet out of automation
        app.launchArguments = ["-bb.review.prompted.v1", "YES"]
        app.launch()
    }

    func testWeeklyMonthlySummary() throws {
        ensureInApp()
        signInFromProfileIfGuest()

        tapTab("记账")
        // 已有账单 → 结余卡可点；空账本 → 先记一笔再进总结
        if !tapCard(containing: "总结与建议") {
            addExpenseViaKeypad()
            XCTAssertTrue(tapCard(containing: "总结与建议"), "记账总结入口未出现")
        }

        XCTAssertTrue(waitForText("记账总结", timeout: 8), "总结页未打开")
        let toggle = app.segmentedControls["summary.scope"].firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 6), "周/月切换不存在")
        save("s1-month")

        // 月 → 周: stats retitle and AI advice reloads for the weekly window.
        toggle.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(waitForText("本周支出", timeout: 6), "周视图未生效")
        XCTAssertTrue(adviceSettled(timeout: 30), "本周 AI 建议区未出结果")
        save("s2-week")

        toggle.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(waitForText("本月支出", timeout: 6), "切回月视图失败")
        XCTAssertTrue(adviceSettled(timeout: 30), "本月 AI 建议区未出结果")
        save("s3-month-back")
    }

    // Advice settled = spinner gone AND a reply rendered (real AI text almost
    // always contains 建议/省/花; the graceful fallback line also counts).
    private func adviceSettled(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        let replyPredicate = NSPredicate(
            format: "label CONTAINS %@ OR label CONTAINS %@ OR label CONTAINS %@", "建议", "省", "花")
        while Date() < deadline {
            let spinnerGone = !app.staticTexts["正在分析你的花销…"].exists
            let hasReply = app.staticTexts.matching(replyPredicate).firstMatch.exists
            if spinnerGone && (hasReply || fallbackShown()) { return true }
            sleep(2)
        }
        return false
    }
    private func fallbackShown() -> Bool {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "没连上 AI")).firstMatch.exists
    }

    // MARK: shared helpers (element-based tab taps; login via 我的 sheet)

    private func ensureInApp() {
        if app.staticTexts["选择语言"].waitForExistence(timeout: 3) {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "中文")).firstMatch.tap()
            sleep(1)
        }
        if app.buttons["跳过"].waitForExistence(timeout: 3) { app.buttons["跳过"].tap() }
        XCTAssertTrue(waitForText("今 日 故 事", timeout: 15), "未进入主界面")
    }

    private func signInFromProfileIfGuest() {
        tapTab("我的")
        guard waitForText("未登录", timeout: 4) else { return }   // already signed in
        tapButton(containing: "登录 / 注册")
        XCTAssertTrue(waitForText("欢迎回来", timeout: 6), "登录页未打开")
        let idField = app.textFields["手机号或邮箱"].exists ? app.textFields["手机号或邮箱"] : app.textFields.element(boundBy: 0)
        XCTAssertTrue(idField.waitForExistence(timeout: 5))
        idField.tap(); idField.typeText(account)
        let pwField = app.secureTextFields.element(boundBy: 0)
        pwField.tap(); pwField.typeText(password)
        tapButton(containing: "登录")
        XCTAssertTrue(waitForText("审核演示", timeout: 20), "登录未完成")
        dismissSavePasswordPromptIfNeeded()
        // Relaunch to a clean logged-in UI (session cookie persists).
        app.terminate()
        app.launch()
        _ = waitForText("今 日 故 事", timeout: 15)
    }

    private func addExpenseViaKeypad() {
        let plus = app.navigationBars.buttons.matching(
            NSPredicate(format: "identifier CONTAINS %@ OR label CONTAINS %@", "plus", "添加")).firstMatch
        if plus.waitForExistence(timeout: 4), plus.isHittable { plus.tap() }
        XCTAssertTrue(waitForText("记一笔", timeout: 5), "记一笔未打开")
        app.buttons["1"].firstMatch.tap()
        app.buttons["5"].firstMatch.tap()
        tapButton(containing: "记一笔")
        _ = waitForText("记一次选择", timeout: 5)
        tapButtonIfExists(containing: "跳过")
        sleep(1)
    }

    @discardableResult
    private func tapCard(containing text: String) -> Bool {
        let el = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        guard el.waitForExistence(timeout: 4), el.isHittable else { return false }
        el.tap(); return true
    }

    private func tapTab(_ label: String) {
        let tabButton = app.tabBars.buttons[label].firstMatch
        if tabButton.waitForExistence(timeout: 2), tabButton.isHittable { tabButton.tap(); sleep(1); return }
        let anyButton = app.buttons[label].firstMatch
        if anyButton.waitForExistence(timeout: 2), anyButton.isHittable { anyButton.tap(); sleep(1) }
    }

    private func waitForText(_ text: String, timeout: TimeInterval) -> Bool {
        let p = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.matching(p).firstMatch.waitForExistence(timeout: timeout)
            || app.buttons.matching(p).firstMatch.waitForExistence(timeout: 0.2)
            || app.navigationBars.matching(p).firstMatch.waitForExistence(timeout: 0.2)
    }

    private func tapButton(containing text: String) {
        let target = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        for _ in 0..<8 {
            if target.exists && target.isHittable { usleep(400_000); target.tap(); return }
            app.swipeUp(); usleep(300_000)
        }
        if target.exists { target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() }
    }

    private func tapButtonIfExists(containing text: String) {
        let t = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        if t.waitForExistence(timeout: 2), t.isHittable { t.tap() }
    }

    private func dismissSavePasswordPromptIfNeeded() {
        let sb = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Not Now", "以后", "不存储", "稍后再说"] {
            if sb.buttons[label].waitForExistence(timeout: label == "Not Now" ? 8 : 1) {
                sb.buttons[label].tap(); sleep(1); return
            }
        }
    }

    private func save(_ name: String) {
        let dir = URL(fileURLWithPath: "/Users/chenmingming/Documents/Claude code/BudgetBuddy-V13-Screenshots", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(
            to: dir.appendingPathComponent("\(name).png"), options: .atomic)
    }
}
