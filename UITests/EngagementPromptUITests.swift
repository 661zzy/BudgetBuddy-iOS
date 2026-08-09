import XCTest

// v1.5.1 engagement/update prompts: the 3-minute rate-or-feedback funnel and the
// fake-channel update sheet, exercised via their NSArgumentDomain seams.
final class EngagementPromptUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    // Preloaded usage crosses the 3-min threshold → funnel appears within one
    // 5s heartbeat; the feedback exit lands on the one-tap feedback page.
    func testA_FunnelAppearsAndRoutesToFeedback() throws {
        app.launchArguments += ["-bb.usage.seconds", "9999",
                                "-bb.engage.prompted.v1", "NO",
                                "-bb.review.prompted.v1", "NO"]
        app.launch()
        ensureInApp()
        XCTAssertTrue(waitForText("搭子想问你一句", timeout: 20), "Engagement funnel did not appear")
        save("e1-funnel")
        app.buttons["engage.feedback"].tap()
        XCTAssertTrue(waitForText("问题反馈", timeout: 8), "Feedback page did not open from funnel")
        XCTAssertTrue(app.buttons["feedback.submit"].waitForExistence(timeout: 6),
                      "One-tap submit missing on feedback page")
        XCTAssertTrue(app.buttons["feedback.addshot"].waitForExistence(timeout: 4),
                      "Screenshot attach tile missing on feedback page")
        save("e2-funnel-to-feedback")
    }

    // Fake channel (latestBuild 999 > current) → update sheet on entry; 稍后再说 dismisses.
    func testB_UpdateSheetFromChannelAndDismiss() throws {
        app.launchArguments += ["-bb.test.latestBuild", "999",
                                "-bb.engage.prompted.v1", "YES"]
        app.launch()
        // The sheet can beat onboarding chrome; clear it first if it's already up.
        if !waitForText("有新版本", timeout: 12) {
            ensureInApp()
            XCTAssertTrue(waitForText("有新版本", timeout: 10), "Update sheet did not appear")
        }
        save("e3-update-sheet")
        tapButtonIfExists(containing: "稍后再说")
        // Sheet dismissal is animated — the label lingers in the tree for a
        // beat, so poll for absence instead of asserting on the next frame.
        XCTAssertTrue(waitForTextToDisappear("有新版本", timeout: 8), "Update sheet did not dismiss")
        ensureInApp()
    }

    // MARK: helpers

    private func ensureInApp() {
        if app.staticTexts["选择语言"].waitForExistence(timeout: 3) {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "中文")).firstMatch.tap()
            sleep(1)
        }
        if app.buttons["跳过"].waitForExistence(timeout: 3) { app.buttons["跳过"].tap() }
        XCTAssertTrue(
            waitForText("今 日 故 事", timeout: 15) || waitForText("本 周 概 览", timeout: 0.5)
                || waitForText("搭子想问你一句", timeout: 0.5) || waitForText("有新版本", timeout: 0.5),
            "Did not reach the main app")
    }

    private func waitForText(_ text: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.matching(predicate).firstMatch.waitForExistence(timeout: timeout)
            || app.buttons.matching(predicate).firstMatch.waitForExistence(timeout: 0.2)
    }

    private func waitForTextToDisappear(_ text: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !app.staticTexts.matching(predicate).firstMatch.exists { return true }
            usleep(300_000)
        }
        return !app.staticTexts.matching(predicate).firstMatch.exists
    }

    private func tapButtonIfExists(containing text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.buttons.matching(predicate).firstMatch
        if target.waitForExistence(timeout: 3), target.isHittable { target.tap() }
    }

    private func save(_ name: String) {
        let dir = URL(fileURLWithPath: "/Users/chenmingming/Documents/Claude code/BudgetBuddy-NewStories-Screenshots", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? XCUIScreen.main.screenshot().pngRepresentation
            .write(to: dir.appendingPathComponent("\(name).png"), options: .atomic)
    }
}
