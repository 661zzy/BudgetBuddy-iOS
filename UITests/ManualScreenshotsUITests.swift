import XCTest

// Captures the full user-journey screenshots for the 软著 user manual.
// Tests run alphabetically (testA_ → testD_); testA_ expects a fresh install
// so onboarding and auth screens are visible.
final class ManualScreenshotsUITests: XCTestCase {
    private var app: XCUIApplication!
    private let account = "review@budgetbuddy.cn"
    private let password = "***SCRUBBED***"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - A. Onboarding + Auth screens (fresh install)

    func testA_OnboardingAndAuth() throws {
        // Build 13: language picker precedes onboarding on first launch
        if app.staticTexts["选择语言"].waitForExistence(timeout: 6) {
            save("00-language-select")
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "中文")).firstMatch.tap()
            sleep(1)
        }
        if app.buttons["跳过"].waitForExistence(timeout: 6) {
            save("01-onboarding-slide1")
            tapButton(containing: "下一步")
            sleep(1)
            save("02-onboarding-slide2")
            app.buttons["跳过"].tap()
            sleep(1)
        }

        if loginScreenVisible(timeout: 10) {
            save("03-login")

            // Register mode (segmented picker)
            let registerSeg = app.buttons["注册"]
            if registerSeg.waitForExistence(timeout: 3) {
                registerSeg.tap()
                sleep(1)
                save("04-register")
                app.buttons["登录"].firstMatch.tap()
                sleep(1)
            }

            // Forgot-password sheet
            tapButtonIfExists(containing: "忘记密码")
            sleep(2)
            save("05-forgot-password")
            app.swipeDown(velocity: .fast)
            sleep(1)
            // If swipe didn't dismiss, try a cancel/back control
            if !loginScreenVisible(timeout: 2) {
                tapButtonIfExists(containing: "取消")
                tapButtonIfExists(containing: "返回")
                sleep(1)
            }

            login()
        }

        XCTAssertTrue(mainAppVisible(timeout: 25), "Did not reach logged-in app")
        sleep(2)
        save("06-home")
    }

    // MARK: - B. Tracker flows

    func testB_TrackerFlows() throws {
        ensureLoggedIn()

        tapTab("记账")
        XCTAssertTrue(waitForText("记账", timeout: 10), "Tracker did not load")

        // Add-entry keypad
        app.navigationBars.buttons.matching(NSPredicate(format: "label CONTAINS %@ OR identifier CONTAINS %@", "添加", "plus")).firstMatch.tap()
        if !waitForText("记一笔", timeout: 3) {
            // fallback: toolbar plus by coordinate
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.075)).tap()
        }
        XCTAssertTrue(waitForText("记一笔", timeout: 6), "Add sheet did not open")
        tapKeypad("1"); tapKeypad("5")
        let note = app.textFields.firstMatch
        if note.waitForExistence(timeout: 2) {
            note.tap()
            note.typeText("和同学买了杯奶茶")
            dismissKeyboard()
        }
        sleep(1)
        save("07-add-entry-keypad")

        // Save → reflection sheet
        tapButton(containing: "记一笔")
        XCTAssertTrue(waitForText("记一次选择", timeout: 8), "Reflect sheet did not open")
        sleep(1)
        save("08-reflect-blank")
        tapButtonIfExists(containing: "想要")
        tapButtonIfExists(containing: "临时决定")
        sleep(1)
        save("09-reflect-selected")
        tapButton(containing: "记录这次选择")
        sleep(2)
        save("10-tracker-list")

        // Summary with AI advice
        tapButton(containing: "总结与建议", fallbackIndex: 0)
        XCTAssertTrue(waitForText("记账总结", timeout: 10), "Tracker summary did not open")
        waitForAIAdviceIfNeeded()
        save("11-tracker-summary")
    }

    // MARK: - C. Story / Codex / Learning

    func testC_StoryCodexLearning() throws {
        ensureLoggedIn()

        // Codex first (does not depend on opening a story)
        tapTab("故事")
        ensureInteractiveStoryMode()
        sleep(1)
        save("13-story-path")
        tapButton(containing: "认知图鉴")
        XCTAssertTrue(waitForText("认知图鉴", timeout: 8), "Codex did not open")
        sleep(1)
        save("16-codex")
        // Open first unlocked card detail
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.30, dy: 0.32)).tap()
        sleep(1)
        if waitForText("相关故事", timeout: 3) {
            save("17-codex-detail")
            goBackIfPossible()
        }
        goBackIfPossible()

        // Learning lessons
        tapTab("故事")
        scrollToTop()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.245)).tap()
        sleep(1)
        if !waitForText("什么是预算？", timeout: 3) {
            tapButtonIfExists(containing: "理财课程")
            sleep(1)
        }
        save("18-learning-list")
        tapButton(containing: "什么是预算？")
        _ = waitForText("来自", timeout: 8)
        sleep(1)
        save("19-lesson-video")
        goBackIfPossible()

        // Story scene last (node sits at ~dy 0.33 on the path)
        openStory("一个月生活费大作战")
        sleep(2)
        save("14-story-scene")
        tapButtonIfExists(containing: "顿顿食堂，偶尔加个鸡腿")
        sleep(1)
        save("15-story-outcome")
    }

    // MARK: - D. AI / Profile / Challenges / Feedback / Legal

    func testD_AIProfileChallenges() throws {
        ensureLoggedIn()

        tapTab("AI搭子")
        XCTAssertTrue(waitForText("AI搭子", timeout: 8), "AI tab did not load")
        sendAIMessage("我这个月在奶茶上花得有点多，怎么省一点？")
        sleep(30)
        dismissKeyboardForScreenshot()
        save("20-ai-chat")

        tapTab("我的")
        XCTAssertTrue(waitForText("账 户", timeout: 8) || waitForText("我的", timeout: 2), "Profile did not load")
        sleep(1)
        save("21-profile")

        tapButton(containing: "我的挑战")
        XCTAssertTrue(waitForText("我的挑战", timeout: 8), "Challenges did not open")
        sleep(1)
        save("22-challenges")
        goBackIfPossible()

        tapButton(containing: "问题反馈")
        XCTAssertTrue(waitForText("问题反馈", timeout: 8), "Feedback did not open")
        sleep(1)
        save("23-feedback")
        goBackIfPossible()

        tapButton(containing: "隐私政策")
        sleep(2)
        save("24-legal-privacy")
    }

    // MARK: - Shared helpers (mirrors AppStoreScreenshotsUITests)

    private func ensureLoggedIn() {
        if mainAppVisible(timeout: 8) { return }
        if app.staticTexts["选择语言"].waitForExistence(timeout: 2) {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "中文")).firstMatch.tap()
            sleep(1)
        }
        if app.buttons["跳过"].waitForExistence(timeout: 3) {
            app.buttons["跳过"].tap()
        }
        if loginScreenVisible(timeout: 10) { login() }
        XCTAssertTrue(mainAppVisible(timeout: 25), "Did not reach logged-in app")
    }

    private func login() {
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

    // Element-based first — bottom-edge coordinates miss the tab buttons under
    // the iOS 26 SDK, and iPadOS 18+ puts the tab bar on TOP.
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

    private func tapKeypad(_ key: String) {
        let b = app.buttons[key]
        if b.waitForExistence(timeout: 2), b.isHittable { b.tap() }
        else { app.staticTexts[key].firstMatch.tap() }
        usleep(300_000)
    }

    private func dismissKeyboard() {
        if app.keyboards.firstMatch.exists {
            for label in ["Hide keyboard", "收起键盘", "Done", "完成", "Return", "换行"] {
                let button = app.keyboards.buttons[label]
                if button.exists && button.isHittable { button.tap(); return }
            }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).tap()
        }
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
        if target.waitForExistence(timeout: 2), target.isHittable { target.tap() }
    }

    private func tapButton(containing text: String, fallbackIndex: Int? = nil) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.buttons.matching(predicate).firstMatch
        for _ in 0..<10 {
            if target.exists && target.isHittable { target.tap(); return }
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
        if app.staticTexts.matching(loading).firstMatch.exists { sleep(12) } else { sleep(6) }
    }

    private func sendAIMessage(_ text: String) {
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 8), "Missing AI input")
        field.tap()
        field.typeText(text)
        let sendPredicate = NSPredicate(format: "label CONTAINS %@ OR identifier CONTAINS %@", "Arrow Up", "arrow.up")
        let send = app.buttons.matching(sendPredicate).firstMatch
        if send.waitForExistence(timeout: 3), send.isHittable { send.tap() }
        else { field.typeText("\n") }
    }

    private func dismissKeyboardForScreenshot() {
        if app.keyboards.firstMatch.exists {
            for label in ["Hide keyboard", "收起键盘", "Done", "完成", "Return", "换行"] {
                let button = app.keyboards.buttons[label]
                if button.exists && button.isHittable { button.tap(); sleep(1); break }
            }
        }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.16)).tap()
        sleep(1)
    }

    private func openStory(_ title: String) {
        tapTab("故事")
        if !(waitForText("互 动 故 事", timeout: 6) || waitForText("理财课程", timeout: 1)) {
            tapButtonIfExists(containing: "进入故事")
        }
        ensureInteractiveStoryMode()
        scrollToTop()
        for point in [
            CGVector(dx: 0.50, dy: 0.33),
            CGVector(dx: 0.50, dy: 0.36),
            CGVector(dx: 0.50, dy: 0.30),
        ] {
            app.coordinate(withNormalizedOffset: point).tap()
            if waitForText("开始游戏", timeout: 2) { break }
        }
        if !waitForText("开始游戏", timeout: 1) { tapText(containing: title) }
        XCTAssertTrue(waitForText("开始游戏", timeout: 8), "Missing start button for \(title)")
        tapButton(containing: "开始游戏")
    }

    private func ensureInteractiveStoryMode() {
        if waitForText("互 动 故 事", timeout: 1) { return }
        scrollToTop()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.28, dy: 0.16)).tap()
        sleep(1)
        if !waitForText("互 动 故 事", timeout: 2) {
            tapButtonIfExists(containing: "互动故事")
        }
        XCTAssertTrue(waitForText("互 动 故 事", timeout: 5), "Interactive story mode did not load")
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
        let out = ProcessInfo.processInfo.environment["MANUAL_SCREENSHOT_DIR"]
            ?? "/Users/chenmingming/Documents/Claude code/BudgetBuddy-Manual-Screenshots"
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
