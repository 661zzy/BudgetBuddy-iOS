import XCTest

final class StabilityFlowUITests: XCTestCase {
    private var app: XCUIApplication!
    private let password = "***SCRUBBED***"
    private let nickname = "测试"

    private var account: String {
        ProcessInfo.processInfo.environment["STABILITY_ACCOUNT"]
            ?? "__iostability_\(Int(Date().timeIntervalSince1970))@budgetbuddy.local"
    }

    private var outputDirectory: URL {
        let path = ProcessInfo.processInfo.environment["STABILITY_SCREENSHOT_DIR"]
            ?? "/Users/chenmingming/Documents/Claude code/BudgetBuddy-iOS-TestScreenshots/stability-runs"
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--stability-flow"]
    }

    func testColdStartFullFlowThreeRounds() throws {
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        appendSummary("account=\(account)")

        app.launch()
        registerFreshAccountIfNeeded()

        for round in 1...3 {
            XCTContext.runActivity(named: "R\(round) cold start + full flow") { _ in
                if round > 1 {
                    coldStart(round: round)
                }

                verifyLoggedInAndNoUpdatePrompt(round: round)
                verifyHome(round: round)
                playStoryToEnding(round: round)
                verifyLearningVideo(round: round)
                verifyCodex(round: round)
                verifyAIBuddy(round: round)
                let amount = 10 + round
                addExpenseAndVerifyPersistence(round: round, amount: amount)
                verifyTrackerSummary(round: round)
                verifyChallenge(round: round)
                verifyProfileFeedbackAndDeleteCancel(round: round)
                appendSummary("R\(round)=PASS")
            }
        }
    }

    private func registerFreshAccountIfNeeded() {
        if skipOnboardingIfNeeded() {
            XCTAssertTrue(loginScreenVisible(timeout: 12), "Onboarding skipped but auth screen did not appear")
        }

        if mainAppVisible(timeout: 8) {
            appendSummary("initial_state=already_logged_in")
            return
        }

        XCTAssertTrue(loginScreenVisible(timeout: 15), "Auth screen did not appear")

        tapSegmentOrButton(containing: "注册")

        let idField = app.textFields["手机号或邮箱"].exists ? app.textFields["手机号或邮箱"] : app.textFields.element(boundBy: 0)
        XCTAssertTrue(idField.waitForExistence(timeout: 8), "Missing identifier field")
        idField.tap()
        idField.typeText(account)

        let passwordField = app.secureTextFields["密码（至少 6 位）"].exists ? app.secureTextFields["密码（至少 6 位）"] : app.secureTextFields.element(boundBy: 0)
        XCTAssertTrue(passwordField.waitForExistence(timeout: 8), "Missing password field")
        passwordField.tap()
        passwordField.typeText(password)

        let nickField = app.textFields["昵称"].exists ? app.textFields["昵称"] : app.textFields.element(boundBy: 1)
        XCTAssertTrue(nickField.waitForExistence(timeout: 8), "Missing nickname field")
        nickField.tap()
        nickField.typeText(nickname)

        tapButton(containing: "注册并登录")
        dismissSavePasswordPromptIfNeeded()
        XCTAssertTrue(mainAppVisible(timeout: 35), "Register/login did not reach main app")
        appendSummary("registered=\(account)")
    }

    @discardableResult
    private func skipOnboardingIfNeeded() -> Bool {
        if app.buttons["跳过"].waitForExistence(timeout: 4) {
            app.buttons["跳过"].tap()
            return true
        }
        if waitForText("开始体验", timeout: 1) {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.075)).tap()
            return true
        }
        return false
    }

    private func coldStart(round: Int) {
        appendSummary("R\(round).cold_start=terminate+launch")
        app.terminate()
        Thread.sleep(forTimeInterval: 1.0)
        app.launch()
        XCTAssertTrue(mainAppVisible(timeout: 30), "R\(round): cold start did not land in logged-in app")
    }

    private func verifyLoggedInAndNoUpdatePrompt(round: Int) {
        XCTAssertFalse(loginScreenVisible(timeout: 1), "R\(round): lost login and returned to auth screen")
        XCTAssertFalse(waitForText("有新版本", timeout: 1), "R\(round): unexpected optional update prompt")
        XCTAssertFalse(waitForText("需要更新", timeout: 1), "R\(round): unexpected forced update prompt")
        XCTAssertFalse(waitForText("去更新", timeout: 1), "R\(round): unexpected update action")
        appendSummary("R\(round).launch=logged_in_no_update_prompt")
    }

    private func verifyHome(round: Int) {
        tapTab("首页")
        XCTAssertTrue(waitForText("省钱搭子", timeout: 10), "R\(round): missing home wordmark")
        XCTAssertTrue(waitForText("BUDGETBUDDY", timeout: 3), "R\(round): missing BudgetBuddy wordmark")
        XCTAssertTrue(waitForText("一个月生活费大作战", timeout: 3), "R\(round): missing 今日故事 hero")
        XCTAssertTrue(waitForText("进入故事", timeout: 3), "R\(round): missing 进入故事 button")
        XCTAssertTrue(waitForText("记录一次选择", timeout: 3), "R\(round): missing reflection card")
        XCTAssertTrue(waitForText("本 周 概 览", timeout: 3), "R\(round): missing weekly overview")
        XCTAssertTrue(waitForText("搭 子 说", timeout: 3), "R\(round): missing buddy card")
        if round == 1 { save("R1-01-home") }
        appendSummary("R\(round).home=PASS")
    }

    private func playStoryToEnding(round: Int) {
        tapTab("故事")
        ensureInteractiveStoryMode()
        openStory("一个月生活费大作战")
        let choices = [
            "顿顿食堂，偶尔加个鸡腿",
            "在学校打球、散步",
            "不需要，先不买",
            "充 ¥30，够用就好",
            "稳住，把余额存进储蓄目标",
        ]
        for choice in choices {
            tapButton(containing: choice)
            tapContinueOrResult()
        }
        XCTAssertTrue(waitForText("做得好", timeout: 10) || waitForText("养成习惯", timeout: 2), "R\(round): story ending did not appear")
        if round == 1 { save("R1-02-story-ending") }
        tapButton(containing: "完成")
        XCTAssertTrue(waitForText("互 动 故 事", timeout: 8), "R\(round): did not return to story tab after ending")
        appendSummary("R\(round).story=PASS")
    }

    private func verifyLearningVideo(round: Int) {
        tapTab("故事")
        scrollToTop()
        tapSegmentOrButton(containing: "理财课程")
        if !waitForText("什么是预算？", timeout: 5) {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.16)).tap()
        }
        XCTAssertTrue(waitForText("什么是预算？", timeout: 8), "R\(round): learning list did not appear")
        tapTextOrButton(containing: "什么是预算？")
        XCTAssertTrue(waitForText("UP主", timeout: 10), "R\(round): lesson video card did not show UP主")
        XCTAssertTrue(waitForText("来自 bilibili", timeout: 3) || waitForText("bilibili", timeout: 1), "R\(round): lesson did not show bilibili provider")
        if round == 1 { save("R1-03-learning-video") }
        goBackIfPossible()
        appendSummary("R\(round).learning_video=PASS")
    }

    private func verifyCodex(round: Int) {
        tapTab("故事")
        ensureInteractiveStoryMode()
        tapButton(containing: "认知图鉴")
        XCTAssertTrue(waitForText("认知图鉴", timeout: 10), "R\(round): codex did not open")
        XCTAssertTrue(waitForText("已解锁", timeout: 8), "R\(round): codex did not show unlocked cards after story")
        goBackIfPossible()
        appendSummary("R\(round).codex=PASS")
    }

    private func verifyAIBuddy(round: Int) {
        tapTab("AI搭子")
        XCTAssertTrue(waitForText("AI搭子", timeout: 8), "R\(round): AI tab did not load")
        let beforeCount = visibleTextCount()
        sendAIMessage("我想少买奶茶，但又怕坚持不了，给我一个具体办法。")
        XCTAssertTrue(waitForAIReply(afterTextCount: beforeCount, timeout: 95), "R\(round): AI reply did not arrive")
        XCTAssertFalse(waitForText("没连上", timeout: 0.5), "R\(round): AI buddy showed offline fallback")
        XCTAssertFalse(waitForText("暂时繁忙", timeout: 0.5), "R\(round): AI buddy showed busy fallback")
        dismissKeyboardForScreenshot()
        if round == 1 { save("R1-04-ai-buddy") }
        appendSummary("R\(round).ai_buddy=PASS")
    }

    private func addExpenseAndVerifyPersistence(round: Int, amount: Int) {
        tapTab("记账")
        XCTAssertTrue(waitForText("记账", timeout: 8), "R\(round): tracker did not load")
        openAddExpenseSheet()
        XCTAssertTrue(waitForText("记一笔", timeout: 8), "R\(round): add sheet did not open")
        for ch in String(amount) { tapButton(containing: String(ch)) }
        tapButton(containing: "记一笔")
        XCTAssertTrue(waitForText("记一次选择", timeout: 10), "R\(round): reflect sheet did not appear")
        tapButton(containing: "需要")
        tapButton(containing: "计划内")
        tapButton(containing: "记录这次选择")
        XCTAssertTrue(waitForText("¥\(amount)", timeout: 20), "R\(round): new expense amount did not appear")
        XCTAssertTrue(waitForText("需要", timeout: 5), "R\(round): new expense did not show 需要 tag")

        app.terminate()
        Thread.sleep(forTimeInterval: 1.0)
        app.launch()
        XCTAssertTrue(mainAppVisible(timeout: 30), "R\(round): app did not return logged-in after post-expense restart")
        verifyLoggedInAndNoUpdatePrompt(round: round)
        tapTab("记账")
        XCTAssertTrue(waitForText("¥\(amount)", timeout: 15), "R\(round): expense disappeared after restart")
        XCTAssertTrue(waitForText("本月结余", timeout: 5), "R\(round): tracker balance card missing after restart")
        if round == 3 { save("R3-07-ledger-after-restart") }
        appendSummary("R\(round).expense_persistence=PASS amount=\(amount)")
    }

    private func verifyTrackerSummary(round: Int) {
        tapTab("记账")
        tapButton(containing: "总结与建议", fallbackIndex: 0)
        XCTAssertTrue(waitForText("记账总结", timeout: 10), "R\(round): tracker summary did not open")
        XCTAssertTrue(waitForText("搭子帮你看看", timeout: 5), "R\(round): tracker AI advice card missing")
        waitForLoadingToDisappear("正在分析你的花销", timeout: 95)
        XCTAssertFalse(waitForText("没连上 AI", timeout: 0.5), "R\(round): tracker summary AI fallback appeared")
        XCTAssertFalse(waitForText("暂时繁忙", timeout: 0.5), "R\(round): tracker summary AI busy fallback appeared")
        if round == 1 { save("R1-05-tracker-summary") }
        goBackIfPossible()
        appendSummary("R\(round).tracker_summary=PASS")
    }

    private func verifyChallenge(round: Int) {
        tapTab("我的")
        tapButton(containing: "我的挑战")
        XCTAssertTrue(waitForText("我的挑战", timeout: 10), "R\(round): challenges screen did not open")
        scrollToTop()
        if !tapVisibleButton(identifierPrefix: "challenge.checkin.button.") {
            if waitForAnyElement(identifierPrefix: "challenge.checkin.state.", timeout: 1)
                || waitForAnyElement(identifierPrefix: "challenge.checkedToday.", timeout: 1)
                || waitForAnyElement(identifierPrefix: "challenge.completed.", timeout: 1) {
                appendSummary("R\(round).challenge=already_confirmed")
                goBackIfPossible()
                return
            }
            scrollToTop()
            XCTAssertTrue(tapVisibleButton(identifierPrefix: "challenge.start.button.") || tapVisibleButton(containing: "开始"), "R\(round): no challenge start button was available")
            scrollToTop()
            XCTAssertTrue(waitForVisibleButton(identifierPrefix: "challenge.checkin.button.", timeout: 8), "R\(round): check-in button did not appear after starting challenge")
            XCTAssertTrue(tapVisibleButton(identifierPrefix: "challenge.checkin.button.") || tapVisibleButton(containing: "今日打卡"), "R\(round): check-in button was not tappable")
        }
        XCTAssertTrue(
            app.descendants(matching: .any)["challenge.checkin.confirmation"].waitForExistence(timeout: 8)
                || waitForAnyElement(identifierPrefix: "challenge.checkedToday.", timeout: 2)
                || waitForAnyElement(identifierPrefix: "challenge.completed.", timeout: 2)
                || waitForAnyElement(identifierPrefix: "challenge.checkin.state.", timeout: 2)
                || waitForText("今天已打卡", timeout: 2)
                || waitForText("挑战完成", timeout: 2)
                || waitForText("太棒了", timeout: 2),
            "R\(round): challenge check-in was not confirmed"
        )
        appendSummary("R\(round).challenge=PASS")
        goBackIfPossible()
    }

    private func verifyProfileFeedbackAndDeleteCancel(round: Int) {
        tapTab("我的")
        XCTAssertTrue(waitForText("我的", timeout: 8), "R\(round): profile tab did not load")
        tapButton(containing: "问题反馈")
        XCTAssertTrue(waitForText("问题反馈", timeout: 8), "R\(round): feedback page did not open")
        XCTAssertTrue(waitForText("App:", timeout: 3), "R\(round): feedback missing app version")
        XCTAssertTrue(waitForText("设备:", timeout: 3), "R\(round): feedback missing device")
        XCTAssertTrue(waitForText("账号:", timeout: 3), "R\(round): feedback missing account")
        XCTAssertTrue(waitForText("数据:", timeout: 3), "R\(round): feedback missing data counts")
        XCTAssertTrue(waitForText("最近操作", timeout: 3), "R\(round): feedback missing diagnostics log section")
        XCTAssertTrue(waitForText("API", timeout: 3), "R\(round): feedback did not show API logs")
        tapButton(containing: "复制诊断信息")
        XCTAssertTrue(waitForText("已复制", timeout: 3), "R\(round): copy diagnostics did not confirm")
        if round == 1 { save("R1-06-feedback") }
        goBackIfPossible()

        tapButton(containing: "删除账号")
        XCTAssertTrue(waitForText("永久删除账号", timeout: 5), "R\(round): delete account sheet did not appear")
        XCTAssertTrue(app.secureTextFields["当前密码"].waitForExistence(timeout: 5), "R\(round): delete password field did not appear")
        if round == 3 { save("R3-08-delete-confirm") }
        tapButton(containing: "取消")
        XCTAssertTrue(waitForText("我的", timeout: 5), "R\(round): delete cancel did not return to profile")
        appendSummary("R\(round).profile_feedback_delete_cancel=PASS")
    }

    // MARK: - UI helpers

    private func loginScreenVisible(timeout: TimeInterval) -> Bool {
        app.staticTexts["欢迎回来"].waitForExistence(timeout: timeout)
            || app.staticTexts["创建账号"].waitForExistence(timeout: 0.3)
            || app.textFields["手机号或邮箱"].waitForExistence(timeout: 0.3)
    }

    private func mainAppVisible(timeout: TimeInterval) -> Bool {
        waitForText("今 日 故 事", timeout: timeout)
            || waitForText("本 周 概 览", timeout: 0.3)
            || waitForText("搭 子 说", timeout: 0.3)
            || waitForText("进入故事", timeout: 0.3)
    }

    private func tapTab(_ label: String) {
        let x: CGFloat
        switch label {
        case "首页": x = 0.10
        case "记账": x = 0.30
        case "故事": x = 0.50
        case "AI搭子": x = 0.70
        case "我的": x = 0.90
        default: x = 0.50
        }
        app.activate()
        app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.965)).tap()
        Thread.sleep(forTimeInterval: 0.8)
    }

    private func waitForText(_ text: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.matching(predicate).firstMatch.waitForExistence(timeout: timeout)
            || app.buttons.matching(predicate).firstMatch.waitForExistence(timeout: 0.2)
            || app.navigationBars.matching(predicate).firstMatch.waitForExistence(timeout: 0.2)
            || app.links.matching(predicate).firstMatch.waitForExistence(timeout: 0.2)
    }

    private func visibleTextCount() -> Int {
        app.staticTexts.allElementsBoundByIndex.count
    }

    private func tapButton(containing text: String, fallbackIndex: Int? = nil) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.buttons.matching(predicate).firstMatch
        for _ in 0..<12 {
            if target.exists && target.isHittable {
                target.tap()
                return
            }
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.2)
        }
        if let fallbackIndex {
            let fallback = app.buttons.element(boundBy: fallbackIndex)
            XCTAssertTrue(fallback.waitForExistence(timeout: 5), "Missing fallback button \(fallbackIndex) for \(text)")
            fallback.tap()
            return
        }
        XCTFail("Could not tap button containing \(text)")
    }

    private func waitForAnyElement(identifierPrefix: String, timeout: TimeInterval) -> Bool {
        let end = Date().addingTimeInterval(timeout)
        while Date() < end {
            if app.descendants(matching: .any).allElementsBoundByIndex.contains(where: { $0.identifier.hasPrefix(identifierPrefix) && $0.exists }) {
                return true
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
        return false
    }

    private func waitForVisibleButton(identifierPrefix: String, timeout: TimeInterval) -> Bool {
        let end = Date().addingTimeInterval(timeout)
        while Date() < end {
            if visibleButtons(identifierPrefix: identifierPrefix).contains(where: { $0.isHittable }) {
                return true
            }
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.2)
        }
        return false
    }

    @discardableResult
    private func tapVisibleButton(identifierPrefix: String) -> Bool {
        for _ in 0..<14 {
            if let button = visibleButtons(identifierPrefix: identifierPrefix).first(where: { $0.isHittable }) {
                button.tap()
                return true
            }
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.2)
        }
        return false
    }

    @discardableResult
    private func tapVisibleButton(containing text: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        for _ in 0..<14 {
            let buttons = app.buttons.matching(predicate).allElementsBoundByIndex
            if let button = buttons.first(where: { $0.exists && $0.isHittable }) {
                button.tap()
                return true
            }
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.2)
        }
        return false
    }

    private func visibleButtons(identifierPrefix: String) -> [XCUIElement] {
        app.buttons.allElementsBoundByIndex.filter {
            $0.identifier.hasPrefix(identifierPrefix) && $0.exists && $0.frame.intersects(app.frame)
        }
    }

    private func tapSegmentOrButton(containing text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let button = app.buttons.matching(predicate).firstMatch
        if button.waitForExistence(timeout: 2), button.isHittable {
            button.tap()
            return
        }
        let segmented = app.segmentedControls.buttons.matching(predicate).firstMatch
        if segmented.waitForExistence(timeout: 2), segmented.isHittable {
            segmented.tap()
            return
        }
        tapTextOrButton(containing: text)
    }

    private func tapTextOrButton(containing text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let button = app.buttons.matching(predicate).firstMatch
        if button.waitForExistence(timeout: 2), button.isHittable {
            button.tap()
            return
        }
        let staticText = app.staticTexts.matching(predicate).firstMatch
        for _ in 0..<10 {
            if staticText.exists && staticText.isHittable {
                staticText.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                return
            }
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.2)
        }
        XCTAssertTrue(staticText.waitForExistence(timeout: 5), "Could not tap text \(text)")
        staticText.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func dismissSavePasswordPromptIfNeeded() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Not Now", "以后", "不存储", "Not Now"] {
            let button = springboard.buttons[label]
            if button.waitForExistence(timeout: 2) {
                button.tap()
                return
            }
        }
    }

    private func ensureInteractiveStoryMode() {
        scrollToTop()
        if waitForText("互 动 故 事", timeout: 1) { return }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.28, dy: 0.16)).tap()
        Thread.sleep(forTimeInterval: 0.8)
        if !waitForText("互 动 故 事", timeout: 2) {
            tapSegmentOrButton(containing: "互动故事")
        }
        XCTAssertTrue(waitForText("互 动 故 事", timeout: 5), "Interactive story mode did not load")
    }

    private func openStory(_ title: String) {
        scrollToTop()
        for point in [
            CGVector(dx: 0.50, dy: 0.34),
            CGVector(dx: 0.50, dy: 0.37),
            CGVector(dx: 0.50, dy: 0.40),
            CGVector(dx: 0.42, dy: 0.36),
            CGVector(dx: 0.58, dy: 0.36),
        ] {
            app.coordinate(withNormalizedOffset: point).tap()
            if waitForText("开始游戏", timeout: 1.5) { break }
        }
        if !waitForText("开始游戏", timeout: 1) {
            tapTextOrButton(containing: title)
        }
        XCTAssertTrue(waitForText("开始游戏", timeout: 8), "Missing start button for \(title)")
        tapButton(containing: "开始游戏")
    }

    private func tapContinueOrResult() {
        if app.buttons["继续"].waitForExistence(timeout: 2) {
            app.buttons["继续"].tap()
            return
        }
        let result = app.buttons["看看结果"]
        XCTAssertTrue(result.waitForExistence(timeout: 8), "Missing 继续 / 看看结果 button")
        result.tap()
    }

    private func sendAIMessage(_ text: String) {
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 8), "Missing AI input")
        field.tap()
        field.typeText(text)
        let sendPredicate = NSPredicate(format: "label CONTAINS %@ OR identifier CONTAINS %@", "Arrow Up", "arrow.up")
        let send = app.buttons.matching(sendPredicate).firstMatch
        if send.waitForExistence(timeout: 3), send.isHittable {
            send.tap()
        } else {
            field.typeText("\n")
        }
    }

    private func waitForAIReply(afterTextCount: Int, timeout: TimeInterval) -> Bool {
        let end = Date().addingTimeInterval(timeout)
        while Date() < end {
            if visibleTextCount() >= afterTextCount + 2 {
                return true
            }
            if waitForText("没连上", timeout: 0.2) || waitForText("暂时繁忙", timeout: 0.2) {
                return true
            }
            Thread.sleep(forTimeInterval: 1.0)
        }
        return false
    }

    private func waitForLoadingToDisappear(_ text: String, timeout: TimeInterval) {
        let end = Date().addingTimeInterval(timeout)
        while Date() < end {
            if !waitForText(text, timeout: 0.5) {
                return
            }
            Thread.sleep(forTimeInterval: 1.0)
        }
        XCTFail("Loading text did not disappear: \(text)")
    }

    private func dismissKeyboardForScreenshot() {
        if app.keyboards.firstMatch.exists {
            for label in ["Hide keyboard", "收起键盘", "Done", "完成", "Return", "换行"] {
                let button = app.keyboards.buttons[label]
                if button.exists && button.isHittable {
                    button.tap()
                    Thread.sleep(forTimeInterval: 0.5)
                    break
                }
            }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.15)).tap()
        }
    }

    private func openAddExpenseSheet() {
        if waitForText("记录第一次选择", timeout: 1) {
            tapButton(containing: "记录第一次选择")
            return
        }
        let add = app.buttons["Add"].exists ? app.buttons["Add"] : app.buttons["plus"]
        if add.waitForExistence(timeout: 1), add.isHittable {
            add.tap()
            return
        }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.085)).tap()
    }

    private func goBackIfPossible() {
        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.exists && back.isHittable {
            back.tap()
            Thread.sleep(forTimeInterval: 0.8)
        }
    }

    private func scrollToTop() {
        for _ in 0..<4 {
            app.swipeDown()
            Thread.sleep(forTimeInterval: 0.1)
        }
    }

    private func save(_ name: String) {
        let url = outputDirectory.appendingPathComponent("\(name).png")
        do {
            try XCUIScreen.main.screenshot().pngRepresentation.write(to: url, options: .atomic)
            appendSummary("screenshot=\(url.path)")
        } catch {
            XCTFail("Failed to write screenshot \(name): \(error)")
        }
    }

    private func appendSummary(_ line: String) {
        let url = outputDirectory.appendingPathComponent("summary.txt")
        let text = line + "\n"
        if let data = text.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: url.path),
               let handle = try? FileHandle(forWritingTo: url) {
                try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
                try? handle.close()
            } else {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
}
