import XCTest

// v1.6.2 反馈回复 against the REAL backend (4.9 must be deployed). Driven by
// scripts/feedback_live_e2e.sh, which replies from the ops API between the two
// halves and deletes the test thread at the end:
//   testA  guest sends a feedback carrying BB_E2E_MARKER → it shows in 我的反馈
//   (script replies with BB_E2E_REPLY)
//   testB  relaunch → Home banner → the reply → a follow-up
// Skips unless BB_E2E_MARKER is set, so it never runs by accident.
final class FeedbackRepliesLiveUITests: XCTestCase {
    private var app: XCUIApplication!
    private let env = ProcessInfo.processInfo.environment
    private var marker: String { env["BB_E2E_MARKER"] ?? "" }
    private var outDir: URL {
        let p = env["BB_SITE_SHOT_DIR"] ?? "/Users/chenmingming/Documents/Claude code/BudgetBuddy-1.6.2-反馈回复/shots"
        let u = URL(fileURLWithPath: p, isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipIf(marker.isEmpty, "Set BB_E2E_MARKER (via scripts/feedback_live_e2e.sh) to run against the live backend")
        app = XCUIApplication()
        app.launchArguments += ["-bb.lang", "zh", "-bb.engage.prompted.v1", "YES", "-bb.review.prompted.v1", "YES"]
        app.launch()
        ensureInApp()
    }

    func testA_GuestSendsFeedback() throws {
        tapTab("我的")
        let row = app.buttons["profile.feedback"]
        for _ in 0..<5 where !row.isHittable { app.swipeUp() }
        row.tap()
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 6), "feedback editor missing")
        editor.tap()
        editor.typeText(marker)
        if app.toolbars.buttons["完成"].exists { app.toolbars.buttons["完成"].tap() }
        let submit = app.buttons["feedback.submit"]
        for _ in 0..<6 where !submit.isHittable { app.swipeUp() }
        submit.tap()
        XCTAssertTrue(app.staticTexts["我们回复后，会显示在这一页上方的「我的反馈」里。"].waitForExistence(timeout: 20),
                      "feedback was not sent (or the server has no reply endpoints)")
        for _ in 0..<8 { app.swipeDown() }
        let listed = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "feedback.thread.", marker)).firstMatch
        XCTAssertTrue(listed.waitForExistence(timeout: 15), "sent feedback not listed under 我的反馈")
        XCTAssertTrue(listed.label.contains("等待回复"), listed.label)
        shoot("live-1-sent")
    }

    func testB_SeesReplyAndFollowsUp() throws {
        let reply = env["BB_E2E_REPLY"] ?? ""
        let banner = app.buttons["feedback.banner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 20), "no reply banner — did the script reply?")
        shoot("live-2-banner")
        banner.tap()
        XCTAssertTrue(app.staticTexts[reply].waitForExistence(timeout: 8), "team reply text missing")
        let composer = app.textFields["feedback.composer"].exists ? app.textFields["feedback.composer"] : app.textViews["feedback.composer"]
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        composer.tap()
        composer.typeText(marker + " 追问")
        app.buttons["feedback.composer.send"].tap()
        XCTAssertTrue(app.staticTexts[marker + " 追问"].waitForExistence(timeout: 15), "follow-up did not post")
        shoot("live-3-follow-up")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let deadline = Date().addingTimeInterval(8)
        while banner.exists && Date() < deadline { usleep(200_000) }
        XCTAssertFalse(banner.exists, "banner still shown after reading")
    }

    // MARK: helpers

    private func shoot(_ name: String) {
        try? XCUIScreen.main.screenshot().pngRepresentation
            .write(to: outDir.appendingPathComponent("\(name).png"), options: .atomic)
    }

    private func ensureInApp() {
        if app.staticTexts["选择语言"].waitForExistence(timeout: 4) {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "中文")).firstMatch.tap(); sleep(1)
        }
        if app.buttons["跳过"].waitForExistence(timeout: 2) { app.buttons["跳过"].tap() }
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 15)
    }

    private func tapTab(_ label: String) {
        let t = app.tabBars.buttons[label].firstMatch
        XCTAssertTrue(t.waitForExistence(timeout: 5), "tab \(label) missing")
        t.tap(); sleep(1)
    }
}
