import XCTest

// v1.5.3 probes: update-skip persistence, the reminder row, the age row at
// sign-up, and the reminder card on a story's ending screen. Screenshots go
// to BB_SITE_SHOT_DIR (or the default folder) for a human look.
final class V153ProbeUITests: XCTestCase {
    private var app: XCUIApplication!
    private let firstChoices = [
        "顿顿食堂，偶尔加个鸡腿",
        "在学校打球、散步",
        "不需要，先不买",
        "充 ¥30，够用就好",
        "稳住，把余额存进储蓄目标"
    ]
    private var outDir: URL {
        let p = ProcessInfo.processInfo.environment["BB_SITE_SHOT_DIR"]
            ?? "/Users/chenmingming/Documents/Claude code/BudgetBuddy-1.5.3-任务包/probe-shots"
        let u = URL(fileURLWithPath: p, isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-bb.lang", "zh", "-bb.engage.prompted.v1", "YES", "-bb.review.prompted.v1", "YES"]
    }

    func testA_UpdateSkipPersists() throws {
        app.launchArguments += ["-bb.test.latestBuild", "999"]
        app.launch(); ensureInApp()
        let skip = app.buttons["update.skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 10), "update sheet or its skip button missing")
        shoot("update-sheet-with-skip")
        skip.tap()
        XCTAssertTrue(waitGone(skip, 5), "sheet did not dismiss")
        app.terminate(); app.launch(); ensureInApp()
        XCTAssertFalse(app.buttons["update.skip"].waitForExistence(timeout: 4), "skipped build was offered again")
    }

    func testB_ReminderRowInProfile() throws {
        app.launch(); ensureInApp()
        tapTab("我的")
        let row = app.switches["profile.reminder"]
        XCTAssertTrue(row.waitForExistence(timeout: 8), "reminder toggle missing in 我的")
        XCTAssertTrue(app.staticTexts["每日故事提醒"].exists)
        shoot("profile-reminder-row")
    }

    func testC_AgeRowAtSignUp() throws {
        app.launch(); ensureInApp()
        tapTab("我的")
        tapButton(containing: "登录 / 注册")
        XCTAssertTrue(app.staticTexts["欢迎回来"].waitForExistence(timeout: 8))
        app.buttons["注册"].firstMatch.tap()
        XCTAssertTrue(app.segmentedControls["auth.age"].waitForExistence(timeout: 5)
                        || app.otherElements["auth.age"].waitForExistence(timeout: 1), "age picker missing")
        app.buttons["未满 14 岁"].firstMatch.tap()
        XCTAssertTrue(app.switches["auth.guardian"].waitForExistence(timeout: 4), "guardian toggle missing")
        shoot("signup-age-guardian")
    }

    func testD_ReminderCardOnEnding() throws {
        app.launch(); ensureInApp()
        tapTab("故事")
        let node = app.buttons["story-node-month-life"]
        XCTAssertTrue(node.waitForExistence(timeout: 8)); node.tap()
        tapButton(containing: "开始")
        for label in firstChoices {
            let b = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch
            XCTAssertTrue(b.waitForExistence(timeout: 8), "choice '\(label)' not found"); b.tap()
            sleep(1)
            // consequence card → 继续 (or 看看结果 on the last scene)
            let cont = app.buttons.matching(NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", "继续", "看看结果")).firstMatch
            XCTAssertTrue(cont.waitForExistence(timeout: 6), "no 继续/看看结果 after '\(label)'"); cont.tap()
            sleep(1)
        }
        let card = app.buttons["story.reminder.offer"]
        if !card.waitForExistence(timeout: 10) { shoot("debug-ending-state") }
        XCTAssertTrue(card.waitForExistence(timeout: 10), "reminder offer card missing on ending screen")
        shoot("ending-with-reminder-card")
    }

    // MARK: helpers
    private func shoot(_ name: String) {
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: outDir.appendingPathComponent("\(name).png"), options: .atomic)
    }
    private func waitGone(_ e: XCUIElement, _ t: TimeInterval) -> Bool {
        let d = Date(); while Date().timeIntervalSince(d) < t { if !e.exists { return true }; usleep(200_000) }; return !e.exists
    }
    private func ensureInApp() {
        if app.staticTexts["选择语言"].waitForExistence(timeout: 4) {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "中文")).firstMatch.tap(); sleep(1)
        }
        if app.buttons["跳过"].waitForExistence(timeout: 2) { app.buttons["跳过"].tap() }
        _ = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "今日故事")).firstMatch.waitForExistence(timeout: 15)
    }
    private func tapTab(_ label: String) {
        let t = app.tabBars.buttons[label].firstMatch
        if t.waitForExistence(timeout: 3) { t.tap(); sleep(1); return }
        app.buttons[label].firstMatch.tap(); sleep(1)
    }
    private func tapButton(containing text: String) {
        let b = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        XCTAssertTrue(b.waitForExistence(timeout: 8), "button containing '\(text)' missing"); b.tap(); sleep(1)
    }
}
