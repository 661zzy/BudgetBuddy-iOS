import XCTest

final class AppStoreScreenshotsUITests: XCTestCase {
    private var app: XCUIApplication!
    private let account = "review@budgetbuddy.cn"
    private let password = ProcessInfo.processInfo.environment["BB_REVIEW_PASSWORD"] ?? ""

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-bb.engage.prompted.v1", "YES"]   // keep the 3-min engagement sheet out of automation
        app.launchArguments = ["--appstore-screenshots"]
        app.launch()
        prepareLoggedInState()
    }

    func testCaptureAppStoreSixNineScreenshots() throws {
        tapTab("首页")
        XCTAssertTrue(waitForText("省钱搭子", timeout: 12), "Home did not load")
        save("01-home")

        tapTab("记账")
        XCTAssertTrue(waitForText("记账", timeout: 10), "Tracker did not load")
        tapButton(containing: "总结与建议", fallbackIndex: 0)
        XCTAssertTrue(waitForText("记账总结", timeout: 10), "Tracker summary did not open")
        waitForAIAdviceIfNeeded()
        save("02-tracker-summary")

        tapTab("故事")
        tapButtonIfExists(containing: "互动故事")
        XCTAssertTrue(waitForText("互 动 故 事", timeout: 10) || waitForText("一个月生活费大作战", timeout: 2), "Story path did not load")
        save("03-story-path")

        tapButton(containing: "理财课程")
        tapButton(containing: "什么是预算？")
        XCTAssertTrue(waitForText("来自 bilibili", timeout: 8) || waitForText("UP主", timeout: 2), "Lesson video card did not appear")
        save("04-learning-video-up")

        tapTab("AI搭子")
        XCTAssertTrue(waitForText("AI搭子", timeout: 8), "AI tab did not load")
        sendAIMessage()
        sleep(18)
        save("05-ai-buddy-reply")

        tapTab("故事")
        tapButtonIfExists(containing: "互动故事")
        tapButton(containing: "认知图鉴")
        XCTAssertTrue(waitForText("认知图鉴", timeout: 8), "Codex did not open")
        save("06-codex")
    }

    func testCaptureAppStoreCodexOnly() throws {
        tapTab("首页")
        XCTAssertTrue(waitForText("省钱搭子", timeout: 12), "Home did not load")
        tapButton(containing: "进入故事")
        XCTAssertTrue(waitForText("互 动 故 事", timeout: 10) || waitForText("认知图鉴", timeout: 2), "Story tab did not open from Home")
        tapButton(containing: "认知图鉴")
        XCTAssertTrue(waitForText("认知图鉴", timeout: 8), "Codex did not open")
        save("06-codex")
    }

    func testCaptureAppStoreAIOnly() throws {
        tapTab("AI搭子")
        XCTAssertTrue(waitForText("AI搭子", timeout: 8), "AI tab did not load")
        sendAIMessage()
        sleep(18)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.69)).tap()
        sleep(1)
        save("05-ai-buddy-reply")
    }

    func testCaptureAppStorePolishedFiveScreenshots() throws {
        seedStoryProgressIfNeeded()

        tapTab("首页")
        XCTAssertTrue(waitForText("省钱搭子", timeout: 12), "Home did not load")
        XCTAssertTrue(waitForText("完成故事", timeout: 5), "Home overview did not load")
        save("01-home")

        tapTab("记账")
        XCTAssertTrue(waitForText("记账", timeout: 10), "Tracker did not load")
        tapButton(containing: "总结与建议", fallbackIndex: 0)
        XCTAssertTrue(waitForText("记账总结", timeout: 10), "Tracker summary did not open")
        waitForAIAdviceIfNeeded()
        XCTAssertTrue(waitForText("¥214", timeout: 3), "Tracker summary did not show the expected demo balance")
        XCTAssertTrue(waitForText("交通", timeout: 3), "Tracker summary did not show the localized transit category")
        XCTAssertFalse(waitForText("transport", timeout: 0.5), "Tracker summary still shows raw transport key")
        save("02-tracker-summary")
        goBackIfPossible()

        tapTab("故事")
        ensureInteractiveStoryMode()
        XCTAssertTrue(waitForText("已通关", timeout: 8), "Story path did not show completed progress")
        save("03-story-path")

        tapTab("AI搭子")
        XCTAssertTrue(waitForText("AI搭子", timeout: 8), "AI tab did not load")
        sendAIMessage("我这个月在奶茶上花得有点多，怎么省一点？")
        waitForAIReply()
        dismissKeyboardForScreenshot()
        XCTAssertFalse(waitForText("没连上", timeout: 0.5), "AI screenshot shows fallback copy")
        save("05-ai-buddy-reply")

        tapTab("故事")
        ensureInteractiveStoryMode()
        tapButton(containing: "认知图鉴")
        XCTAssertTrue(waitForText("认知图鉴", timeout: 8), "Codex did not open")
        XCTAssertTrue(waitForText("已解锁", timeout: 8), "Codex did not show an unlocked card")
        save("06-codex")
    }

    private func prepareLoggedInState() {
        if mainAppVisible(timeout: 8) {
            return
        }

        if app.buttons["跳过"].waitForExistence(timeout: 3) {
            app.buttons["跳过"].tap()
        } else if !loginScreenVisible(timeout: 1) {
            // The onboarding "跳过" control sometimes exposes as text, not a
            // button, under XCTest. Its visual position is stable.
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.08)).tap()
            sleep(1)
        }

        if loginScreenVisible(timeout: 10) {
            let idField = app.textFields["手机号或邮箱"].exists ? app.textFields["手机号或邮箱"] : app.textFields.element(boundBy: 0)
            XCTAssertTrue(idField.waitForExistence(timeout: 5), "Missing identifier field")
            idField.tap()
            idField.typeText(account)

            let passwordField = app.secureTextFields["密码（至少 6 位）"].exists ? app.secureTextFields["密码（至少 6 位）"] : app.secureTextFields.element(boundBy: 0)
            XCTAssertTrue(passwordField.waitForExistence(timeout: 5), "Missing password field")
            passwordField.tap()
            passwordField.typeText(password)

            tapButton(containing: "登录")
            dismissSavePasswordPromptIfNeeded()
        }

        XCTAssertTrue(mainAppVisible(timeout: 25), "Did not reach logged-in app")
    }

    private func loginScreenVisible(timeout: TimeInterval) -> Bool {
        app.staticTexts["欢迎回来"].waitForExistence(timeout: timeout)
            || app.buttons["登录"].waitForExistence(timeout: 0.5)
            || app.textFields["手机号或邮箱"].waitForExistence(timeout: 0.5)
    }

    private func mainAppVisible(timeout: TimeInterval) -> Bool {
        waitForText("今 日 故 事", timeout: timeout)
            || waitForText("本 周 概 览", timeout: 0.5)
            || waitForText("搭 子 说", timeout: 0.5)
    }

    private func dismissSavePasswordPromptIfNeeded() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.buttons["Not Now"].waitForExistence(timeout: 4) {
            springboard.buttons["Not Now"].tap()
        } else if springboard.buttons["以后"].waitForExistence(timeout: 1) {
            springboard.buttons["以后"].tap()
        } else if springboard.buttons["不存储"].waitForExistence(timeout: 1) {
            springboard.buttons["不存储"].tap()
        }
    }

    // Element-based first (isHittable guards the invalid-hit-point case the old
    // custom tab bar had); bottom-edge coordinates miss the tab buttons under the
    // iOS 26 SDK, and iPadOS 18+ puts the tab bar on TOP.
    private func tapTab(_ label: String) {
        let tabButton = app.tabBars.buttons[label].firstMatch
        if tabButton.waitForExistence(timeout: 2), tabButton.isHittable {
            tabButton.tap(); sleep(1); return
        }
        let anyButton = app.buttons[label].firstMatch
        if anyButton.waitForExistence(timeout: 2), anyButton.isHittable {
            anyButton.tap(); sleep(1); return
        }
        let x: CGFloat
        switch label {
        case "首页": x = 0.10
        case "记账": x = 0.30
        case "故事": x = 0.50
        case "AI搭子": x = 0.70
        case "我的": x = 0.90
        default: x = 0.50
        }
        app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.965)).tap()
        sleep(1)
    }

    private func waitForText(_ text: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.matching(predicate).firstMatch.waitForExistence(timeout: timeout)
            || app.buttons.matching(predicate).firstMatch.waitForExistence(timeout: 0.2)
            || app.navigationBars.matching(predicate).firstMatch.waitForExistence(timeout: 0.2)
    }

    private func tapButtonIfExists(containing text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.buttons.matching(predicate).firstMatch
        if target.waitForExistence(timeout: 2), target.isHittable {
            target.tap()
        }
    }

    private func tapButton(containing text: String, fallbackIndex: Int? = nil) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.buttons.matching(predicate).firstMatch
        for _ in 0..<10 {
            if target.exists && target.isHittable {
                target.tap()
                return
            }
            app.swipeUp()
        }

        if target.exists {
            target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return
        }

        if let fallbackIndex {
            let fallback = app.buttons.element(boundBy: fallbackIndex)
            XCTAssertTrue(fallback.waitForExistence(timeout: 5), "Missing fallback button \(fallbackIndex) for \(text)")
            fallback.tap()
            return
        }

        XCTFail("Could not tap button containing \(text)")
    }

    private func waitForAIAdviceIfNeeded() {
        let loading = NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", "正在分析", "稍等")
        if app.staticTexts.matching(loading).firstMatch.exists {
            sleep(12)
        } else {
            sleep(6)
        }
    }

    private func sendAIMessage(_ text: String = "Give me one practical saving tip") {
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

    private func waitForAIReply() {
        // Build 7 allows up to three 45s attempts, but the happy path usually returns quickly.
        // For App Store screenshots we wait generously, then fail only if the honest fallback appears.
        sleep(35)
    }

    private func dismissKeyboardForScreenshot() {
        if app.keyboards.firstMatch.exists {
            for label in ["Hide keyboard", "收起键盘", "Done", "完成", "Return", "换行"] {
                let button = app.keyboards.buttons[label]
                if button.exists && button.isHittable {
                    button.tap()
                    sleep(1)
                    break
                }
            }
        }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.16)).tap()
        sleep(1)
    }

    private func completeFirstStoryForScreenshots() {
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
        finishIfNeeded()
    }

    private func seedStoryProgressIfNeeded() {
        tapTab("故事")
        ensureInteractiveStoryMode()
        if waitForText("已通关", timeout: 2) {
            return
        }
        completeFirstStoryForScreenshots()
    }

    private func openStory(_ title: String) {
        tapTab("故事")
        if !(waitForText("互 动 故 事", timeout: 6) || waitForText("理财课程", timeout: 1)) {
            tapButtonIfExists(containing: "进入故事")
        }
        XCTAssertTrue(waitForText("互 动 故 事", timeout: 8) || waitForText("理财课程", timeout: 1), "Story tab did not load")
        ensureInteractiveStoryMode()
        scrollToTop()
        // The visible story title is a separate label; the tappable NavigationLink is
        // the circular node above it. Tap likely node centers first, then fall back to
        // text/button matching for older layouts.
        for point in [
            CGVector(dx: 0.50, dy: 0.22),
            CGVector(dx: 0.50, dy: 0.25),
            CGVector(dx: 0.50, dy: 0.28),
        ] {
            app.coordinate(withNormalizedOffset: point).tap()
            if waitForText("开始游戏", timeout: 2) { break }
        }
        if !waitForText("开始游戏", timeout: 1), !tapButtonIfVisible(containing: title) {
            tapText(containing: title)
        }
        XCTAssertTrue(waitForText("开始游戏", timeout: 8), "Missing start button for \(title)")
        tapButton(containing: "开始游戏")
    }

    private func ensureInteractiveStoryMode() {
        if waitForText("互 动 故 事", timeout: 1) { return }
        scrollToTop()
        // Left mode card: "互动故事 / 情景里做决定".
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.28, dy: 0.16)).tap()
        sleep(1)
        if !waitForText("互 动 故 事", timeout: 2) {
            tapButtonIfExists(containing: "互动故事")
        }
        XCTAssertTrue(waitForText("互 动 故 事", timeout: 5), "Interactive story mode did not load")
    }

    @discardableResult
    private func tapButtonIfVisible(containing text: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.buttons.matching(predicate).firstMatch
        if target.waitForExistence(timeout: 2), target.isHittable {
            target.tap()
            return true
        }
        return false
    }

    private func tapText(containing text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.staticTexts.matching(predicate).firstMatch
        for _ in 0..<8 {
            if target.exists && target.isHittable {
                target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                return
            }
            app.swipeUp()
        }
        XCTAssertTrue(target.waitForExistence(timeout: 5), "Could not tap text \(text)")
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func tapContinueOrResult() {
        let continueButton = app.buttons["继续"]
        if continueButton.waitForExistence(timeout: 2) {
            continueButton.tap()
            return
        }
        let resultButton = app.buttons["看看结果"]
        XCTAssertTrue(resultButton.waitForExistence(timeout: 8), "Missing 继续 / 看看结果 button")
        resultButton.tap()
    }

    private func finishIfNeeded() {
        if waitForText("完成", timeout: 8) {
            tapButton(containing: "完成")
            return
        }
        goBackIfPossible()
    }

    private func goBackIfPossible() {
        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.exists && back.isHittable {
            back.tap()
            sleep(1)
        }
    }

    private func scrollToTop() {
        for _ in 0..<4 { app.swipeDown() }
    }

    private func save(_ name: String) {
        let out = ProcessInfo.processInfo.environment["APPSTORE_SCREENSHOT_DIR"]
            ?? "/Users/chenmingming/Documents/Claude code/BudgetBuddy-iOS-TestScreenshots/appstore-69"
        let dir = URL(fileURLWithPath: out, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(name).png")
        do {
            try XCUIScreen.main.screenshot().pngRepresentation.write(to: url, options: .atomic)
        } catch {
            XCTFail("Failed to write screenshot \(name): \(error)")
        }
    }
}
