import XCTest

final class GeneratedStoryArtSmokeUITests: XCTestCase {
    private var app: XCUIApplication!

    private let newStoryTitles = [
        "凑单的数学题",
        "首月 0.1 元的会员",
        "直播间的最后三件",
        "648 的诱惑",
        "轮到你请客了",
        "二手平台的「急出」",
        "双十一囤货大战",
        "同学开口借钱",
        "分期买手机划算吗",
        "第一笔工资",
        "「动动手指日入 200」",
        "抢不到的演唱会",
        "健身年卡的算术题",
        "毕业旅行穷游计划",
        "压岁钱保卫战",
        "月中的饭卡告急",
        "追星的钱包",
        "「免费领皮肤」的链接",
        "退货运费的隐藏规则",
        "报班这笔账",
    ]

    private var screenshotDirectory: URL {
        URL(
            fileURLWithPath: ProcessInfo.processInfo.environment["SCENE_ART_SCREENSHOT_DIR"]
                ?? "/tmp/budgetbuddy-scene-art-runtime",
            isDirectory: true
        )
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-bb.engage.prompted.v1", "YES"]   // keep the 3-min engagement sheet out of automation
        app.launchArguments = ["--generated-story-art-smoke"]
        app.launch()
    }

    func testGeneratedStoryArtIsReachableFromStoriesTab() throws {
        try FileManager.default.createDirectory(at: screenshotDirectory, withIntermediateDirectories: true)
        try ensureMainApp()
        openStoriesTab()

        XCTAssertTrue(
            waitForText("INTERACTIVE STORIES", timeout: 8)
                || waitForText("互 动 故 事", timeout: 2)
                || waitForText("互动故事", timeout: 2),
            "Stories tab did not load"
        )

        try saveScreenshot("01-stories-top")

        var found = Set<String>()
        for step in 0..<16 {
            for title in newStoryTitles where textExists(title) {
                found.insert(title)
            }
            if [3, 7, 11, 15].contains(step) {
                try saveScreenshot(String(format: "stories-scroll-%02d", step))
            }
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.35)
        }

        XCTAssertGreaterThanOrEqual(
            found.count,
            15,
            "Expected to reach most newly illustrated stories while scrolling the story path; found \(found.count): \(found.sorted())"
        )
    }

    private func ensureMainApp() throws {
        // Build 13+: first launch starts with the bilingual language picker.
        if app.staticTexts["选择语言"].waitForExistence(timeout: 4) {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "中文")).firstMatch.tap()
            Thread.sleep(forTimeInterval: 0.8)
        }
        if mainVisible(timeout: 12) { switchToChineseIfNeeded(); return }

        if app.buttons["跳过"].waitForExistence(timeout: 2) {
            app.buttons["跳过"].tap()
        }

        guard loginVisible(timeout: 6) else {
            XCTAssertTrue(mainVisible(timeout: 10), "App did not reach main UI or login UI")
            switchToChineseIfNeeded()
            return
        }

        try login(identifier: "__iostest_1782407190@budgetbuddy.local", password: ProcessInfo.processInfo.environment["BB_TEST_PASSWORD"] ?? "")
        if !mainVisible(timeout: 12) {
            try login(identifier: "review@budgetbuddy.cn", password: ProcessInfo.processInfo.environment["BB_REVIEW_PASSWORD"] ?? "")
        }
        XCTAssertTrue(mainVisible(timeout: 25), "Login did not reach the main app")
        switchToChineseIfNeeded()
    }

    /// The story titles this smoke checks are the CHINESE source strings; if a
    /// previous suite left the app in English, flip it back via 我的 → Language.
    private func switchToChineseIfNeeded() {
        guard waitForText("TODAY'S STORY", timeout: 1) || app.staticTexts["Me"].exists else { return }
        tapTabElement("Me", fallbackX: 0.90)   // Me tab (English UI at this point)
        Thread.sleep(forTimeInterval: 1.0)
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Language")).firstMatch
        var tries = 0
        while !(row.exists && row.isHittable) && tries < 8 {
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.3)
            tries += 1
        }
        if row.exists && row.isHittable {
            Thread.sleep(forTimeInterval: 0.5)
            row.tap()
            let zh = app.buttons["中文"].firstMatch
            if zh.waitForExistence(timeout: 3) { zh.tap() }
            Thread.sleep(forTimeInterval: 1.0)
        }
        tapTabElement("首页", fallbackX: 0.10)
        Thread.sleep(forTimeInterval: 0.8)
    }

    // Element-based tab tap — bottom-edge coordinates miss the tab buttons under
    // the iOS 26 SDK, and iPadOS 18+ puts the tab bar on TOP.
    private func tapTabElement(_ label: String, fallbackX: CGFloat) {
        let tabButton = app.tabBars.buttons[label].firstMatch
        if tabButton.waitForExistence(timeout: 2), tabButton.isHittable { tabButton.tap(); return }
        let anyButton = app.buttons[label].firstMatch
        if anyButton.waitForExistence(timeout: 2), anyButton.isHittable { anyButton.tap(); return }
        app.coordinate(withNormalizedOffset: CGVector(dx: fallbackX, dy: 0.965)).tap()
    }

    private func login(identifier: String, password: String) throws {
        let idField = app.textFields["手机号或邮箱"].exists
            ? app.textFields["手机号或邮箱"]
            : app.textFields.element(boundBy: 0)
        XCTAssertTrue(idField.waitForExistence(timeout: 5), "Missing identifier field")
        idField.tap()
        idField.press(forDuration: 1.0)
        app.menuItems["Select All"].tapIfExists()
        idField.typeText(identifier)

        let passwordField = app.secureTextFields["密码（至少 6 位）"].exists
            ? app.secureTextFields["密码（至少 6 位）"]
            : app.secureTextFields.element(boundBy: 0)
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5), "Missing password field")
        passwordField.tap()
        passwordField.press(forDuration: 1.0)
        app.menuItems["Select All"].tapIfExists()
        passwordField.typeText(password)

        tapButton(containing: "登录")
    }

    private func openStoriesTab() {
        if app.tabBars.buttons["Stories"].waitForExistence(timeout: 5) {
            app.tabBars.buttons["Stories"].tap()
            return
        }
        if app.tabBars.buttons["故事"].waitForExistence(timeout: 2) {
            app.tabBars.buttons["故事"].tap()
            return
        }
        tapButton(containing: "Stories")
    }

    private func mainVisible(timeout: TimeInterval) -> Bool {
        waitForText("省钱搭子", timeout: timeout)
            || waitForText("TODAY'S STORY", timeout: 0.5)
            || waitForText("今 日 故 事", timeout: 0.5)
    }

    private func loginVisible(timeout: TimeInterval) -> Bool {
        waitForText("欢迎回来", timeout: timeout)
            || waitForText("Welcome back", timeout: 0.5)
            || app.textFields["手机号或邮箱"].waitForExistence(timeout: 0.5)
    }

    private func waitForText(_ text: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.matching(predicate).firstMatch.waitForExistence(timeout: timeout)
            || app.buttons.matching(predicate).firstMatch.waitForExistence(timeout: 0.2)
    }

    private func textExists(_ text: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.matching(predicate).firstMatch.exists
            || app.buttons.matching(predicate).firstMatch.exists
    }

    private func tapButton(containing text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let button = app.buttons.matching(predicate).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 8), "Missing button containing \(text)")
        button.tap()
    }

    private func saveScreenshot(_ name: String) throws {
        let url = screenshotDirectory.appendingPathComponent("\(name).png")
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: url)
    }
}

private extension XCUIElement {
    func tapIfExists() {
        if exists { tap() }
    }
}
