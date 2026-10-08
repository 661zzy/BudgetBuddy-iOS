import XCTest

// Story verdicts: a trap choice throws a big red alert over the whole screen
// (tab bar included); dismissing it leaves the pick marked "这步有坑"; a right
// choice just gets a green "好选择"; the ending counts the traps.
// Screenshots land in BB_STORYALERT_SHOT_DIR for human review.
final class StoryWrongAlertUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Keep the 3-min engagement sheet and the one-time App Store rating prompt
        // (shown after a good ending) out of automation.
        app.launchArguments += ["-bb.engage.prompted.v1", "YES", "-bb.review.prompted.v1", "YES"]
    }

    func testA_TrapChoiceShowsRedAlertThenEndingCountsIt_ZH() throws {
        app.launchArguments += ["-bb.lang", "zh"]
        app.launch()
        ensureInApp()
        tapTab("故事")
        openFreeSkin(introContains: "免费领皮肤")
        tapButton(containing: "开始游戏")
        XCTAssertTrue(waitForText("同学发来的链接", timeout: 8), "scene 1 missing")
        save("a1-scene1")

        // Scene 1: the trap.
        tapButton(containing: "点开看看")
        XCTAssertTrue(waitForText("这一步有坑", timeout: 5), "red alert did not appear")
        XCTAssertTrue(waitForText("为什么要小心", timeout: 1), "alert lacks the explanation")
        XCTAssertTrue(waitForText("下次可以这样做", timeout: 1), "alert lacks the better move")
        XCTAssertTrue(waitForText("先私聊问小宇", timeout: 1), "alert does not name the right move")
        let tabs = app.tabBars.firstMatch
        XCTAssertFalse(tabs.exists && tabs.isHittable, "tab bar should be covered by the alert")
        save("a2-red-alert")

        // The backdrop swallows taps: only the button closes it.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.03)).tap()
        XCTAssertTrue(app.buttons["story.wrong.ok"].waitForExistence(timeout: 1), "tapping outside closed the alert")

        app.buttons["story.wrong.ok"].tap()
        XCTAssertTrue(waitGone(app.buttons["story.wrong.ok"], timeout: 4), "alert did not close")
        XCTAssertTrue(app.otherElements["story.verdict.wrong"].waitForExistence(timeout: 3)
                      || waitForText("这步有坑", timeout: 2), "picked card not marked wrong")
        save("a3-after-alert")

        // Scene 2: the right move — no alert, green label.
        tapButton(containing: "继续")
        XCTAssertTrue(waitForText("要家长身份证", timeout: 8), "scene 2 missing")
        tapButton(containing: "立刻关闭页面")
        XCTAssertFalse(app.buttons["story.wrong.ok"].waitForExistence(timeout: 1.5), "alert must not fire on a right choice")
        XCTAssertTrue(waitForText("好选择", timeout: 3), "right choice not marked")
        save("a4-good-call")

        // Rest of the run with right answers: s3 → s3b → s4 → ending.
        for (next, pick) in [("卡单", "拉黑举报"), ("防沉迷", "不碰"), ("说出来", "跟家长老师说清楚")] {
            tapButton(containing: "继续")
            XCTAssertTrue(waitForText(next, timeout: 8), "scene with \(next) missing")
            tapButton(containing: pick)
            sleep(1)
        }
        tapButton(containing: "看看结果")
        XCTAssertTrue(waitForText("避开了 4 / 5 个坑", timeout: 8), "ending does not count the trap")
        save("a5-ending-count")

        // Replay with only right answers: no alert, and the count starts over.
        tapButton(containing: "再玩一次")
        for pick in ["先私聊问小宇", "立刻关闭页面", "拉黑举报", "不碰", "跟家长老师说清楚"] {
            tapButton(containing: pick)
            XCTAssertFalse(app.buttons["story.wrong.ok"].waitForExistence(timeout: 1), "alert fired on a right answer: \(pick)")
            tapButton(containing: pick == "跟家长老师说清楚" ? "看看结果" : "继续")
            sleep(1)
        }
        XCTAssertTrue(waitForText("5 个坑全部避开", timeout: 8), "replay did not reset the trap count")
        save("a6-replay-clean")
    }

    func testB_RedAlertInEnglish() throws {
        app.launchArguments += ["-bb.lang", "en"]
        app.launch()
        ensureInApp()
        tapTab("Stories")
        openFreeSkin(introContains: "free skin")
        tapButton(containing: "Start")
        tapButton(containing: "Open it")
        XCTAssertTrue(waitForText("That one's a trap", timeout: 5), "EN red alert missing")
        XCTAssertTrue(waitForText("Try this next time", timeout: 1), "EN better-move section missing")
        XCTAssertTrue(waitForText("Why it's risky", timeout: 1), "EN explanation section missing")
        save("b1-en-red-alert")
        app.buttons["story.wrong.ok"].tap()
        XCTAssertTrue(waitForText("Risky move", timeout: 4), "EN verdict label missing")
        save("b2-en-after-alert")
    }

    func testC_HalfRightChoiceIsMarkedWithoutAlert() throws {
        app.launchArguments += ["-bb.lang", "zh"]
        app.launch()
        ensureInApp()
        tapTab("故事")
        openFreeSkin(introContains: "免费领皮肤")
        tapButton(containing: "开始游戏")
        tapButton(containing: "用小号点进去试试")      // score 1
        XCTAssertFalse(app.buttons["story.wrong.ok"].waitForExistence(timeout: 1.5), "alert must not fire on a half-right choice")
        XCTAssertTrue(waitForText("还能更好", timeout: 3), "half-right choice not marked")
        save("c1-could-be-better")
    }

    // flat-tire has no right answer in any scene, so nothing is judged.
    func testD_StoryWithoutRightAnswersIsNeverJudged() throws {
        app.launchArguments += ["-bb.lang", "zh"]
        app.launch()
        ensureInApp()
        tapTab("故事")
        XCTAssertTrue(scrollToNode("flat-tire"), "flat-tire node not reachable")
        app.buttons["story-node-flat-tire"].tap()
        XCTAssertTrue(waitForText("爆胎的自行车", timeout: 8), "flat-tire intro missing")
        tapButton(containing: "开始游戏")
        tapButton(containing: "推车去前面的修车铺问问")
        XCTAssertFalse(app.buttons["story.wrong.ok"].waitForExistence(timeout: 1.5), "alert fired in a scene with no right answer")
        for id in ["story.verdict.best", "story.verdict.okay", "story.verdict.wrong"] {
            XCTAssertFalse(app.otherElements[id].exists || app.staticTexts[id].exists, "\(id) shown in a scene with no right answer")
        }
        save("d1-neutral-scene")
    }

    // Largest accessibility text: the card scrolls and the button can still be reached.
    func testE_LargestTextStillReachesTheButton() throws {
        app.launchArguments += ["-bb.lang", "zh", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        ensureInApp()
        tapTab("故事")
        openFreeSkin(introContains: "免费领皮肤")
        tapButton(containing: "开始游戏")
        tapButton(containing: "点开看看")
        let ok = app.buttons["story.wrong.ok"]
        XCTAssertTrue(ok.waitForExistence(timeout: 5), "alert missing at the largest text size")
        save("e1-largest-text-top")
        for _ in 0..<8 where !ok.isHittable {
            app.swipeUp()
            usleep(400_000)
        }
        XCTAssertTrue(ok.isHittable, "button not reachable at the largest text size")
        save("e2-largest-text-button")
        ok.tap()
        XCTAssertTrue(waitGone(ok, timeout: 4), "alert did not close at the largest text size")
    }

    // Investor-demo recording, not a check: plays the English route at a human pace and
    // prints timestamps so the screen recording can be trimmed. Skipped unless
    // BB_DEMO_RECORD=1 (pass TEST_RUNNER_BB_DEMO_RECORD=1 to xcodebuild).
    func testZ_RecordEnglishDemo() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["BB_DEMO_RECORD"] == "1", "demo recording only")
        app.launchArguments += ["-bb.lang", "en"]
        app.launch()
        ensureInApp()
        pause(1.0)
        mark("start")
        tapTab("Stories")
        pause(1.2)
        XCTAssertTrue(scrollToNodeGently("free-skin"), "free-skin node not reachable")
        pause(0.8)
        app.buttons["story-node-free-skin"].tap()
        XCTAssertTrue(waitForText("free skin", timeout: 8))
        pause(2.2)
        demoTap("Start")
        pause(2.6)                                   // let the scene read

        demoTap("Open it")                          // the trap
        XCTAssertTrue(app.buttons["story.wrong.ok"].waitForExistence(timeout: 5))
        mark("alert")
        pause(4.5)                                   // the red alert, held long enough to read
        app.buttons["story.wrong.ok"].tap()
        pause(1.8)                                   // the card marked "Risky move"

        demoTap("Continue")
        pause(1.8)
        demoTap("Close the page immediately")       // right answer: green "Good call"
        pause(2.0)
        for (next, pick) in [("Block and report", "Block and report"), ("Don't touch it", "Don't touch it"),
                             ("Tell your parents", "Tell your parents")] {
            demoTap("Continue")
            pause(1.2)
            demoTap(pick)
            _ = next
            pause(1.1)
        }
        demoTap("See the results")
        XCTAssertTrue(waitForText("trap", timeout: 8))
        pause(4.0)                                   // ending: "Fell for 1 trap this round"
        mark("end")
    }

    private func pause(_ seconds: Double) { Thread.sleep(forTimeInterval: seconds) }

    private func mark(_ name: String) {
        print(String(format: "BBDEMO %@ %.3f", name, Date().timeIntervalSince1970))
    }

    /// Scrolls slowly (so the recording reads as a person scrolling) until the button is on screen.
    private func demoTap(_ text: String) {
        let target = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        _ = target.waitForExistence(timeout: 3)
        let limit = app.windows.firstMatch.frame.maxY - 120          // clear of the tab bar
        var lastY = CGFloat.nan
        for _ in 0..<6 {
            guard target.exists else { app.swipeUp(velocity: .slow); continue }
            let y = target.frame.minY
            if target.isHittable && target.frame.maxY < limit { break }
            if abs(y - lastY) < 1 { break }                          // the page no longer moves
            lastY = y
            app.swipeUp(velocity: .slow)
        }
        XCTAssertTrue(target.isHittable, "demo could not reach \(text)")
        pause(0.4)
        target.tap()
    }

    private func scrollToNodeGently(_ id: String) -> Bool {
        let target = app.buttons["story-node-\(id)"]
        _ = target.waitForExistence(timeout: 3)
        var lastY = CGFloat.nan
        for _ in 0..<30 {
            let window = app.windows.firstMatch.frame
            if target.exists && target.isHittable && target.frame.midY < window.maxY * 0.7
                && target.frame.midY > window.minY + 150 { return true }
            if target.exists && abs(target.frame.midY - lastY) < 1 { break }
            lastY = target.exists ? target.frame.midY : .nan
            if target.exists && target.frame.midY < window.minY + 150 { app.swipeDown(velocity: .slow) } else { app.swipeUp(velocity: .fast) }
        }
        return target.exists && target.isHittable
    }

    // MARK: helpers

    private func openFreeSkin(introContains: String) {
        XCTAssertTrue(scrollToNode("free-skin"), "free-skin node not reachable")
        usleep(500_000)
        app.buttons["story-node-free-skin"].tap()
        XCTAssertTrue(waitForText(introContains, timeout: 8), "free-skin intro missing \(introContains)")
    }

    private func scrollToNode(_ id: String) -> Bool {
        let target = app.buttons["story-node-\(id)"]
        let window = app.windows.firstMatch.frame
        for _ in 0..<50 {
            if target.exists && target.isHittable { return true }
            if target.exists && target.frame.midY < window.minY + 120 { app.swipeDown() } else { app.swipeUp() }
            usleep(350_000)
        }
        return target.exists && target.isHittable
    }

    private func ensureInApp() {
        if app.staticTexts["选择语言"].waitForExistence(timeout: 3) {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "中文")).firstMatch.tap()
            sleep(1)
        }
        if app.buttons["跳过"].waitForExistence(timeout: 3) { app.buttons["跳过"].tap() }
        if app.buttons["Skip"].waitForExistence(timeout: 1) { app.buttons["Skip"].tap() }
        XCTAssertTrue(waitForText("今 日 故 事", timeout: 15) || waitForText("TODAY'S STORY", timeout: 1)
                      || waitForText("本 周 概 览", timeout: 1), "Did not reach the main app")
    }

    private func tapTab(_ label: String) {
        let tabButton = app.tabBars.buttons[label].firstMatch
        if tabButton.waitForExistence(timeout: 2), tabButton.isHittable { tabButton.tap(); sleep(1); return }
        // iPad (and other regular-width screens) draw the tabs at the top, outside `tabBars`.
        let anyButton = app.buttons[label].firstMatch
        if anyButton.waitForExistence(timeout: 2), anyButton.isHittable { anyButton.tap(); sleep(1); return }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.965)).tap()
        sleep(1)
    }

    private func waitForText(_ text: String, timeout: TimeInterval) -> Bool {
        let p = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.matching(p).firstMatch.waitForExistence(timeout: timeout)
            || app.buttons.matching(p).firstMatch.waitForExistence(timeout: 0.2)
            || app.otherElements.matching(p).firstMatch.waitForExistence(timeout: 0.2)
    }

    private func waitGone(_ e: XCUIElement, timeout: TimeInterval) -> Bool {
        let exp = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: e)
        return XCTWaiter.wait(for: [exp], timeout: timeout) == .completed
    }

    private func tapButton(containing text: String) {
        let p = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.buttons.matching(p).firstMatch
        for _ in 0..<10 {
            if target.exists && target.isHittable { usleep(400_000); target.tap(); return }
            app.swipeUp()
            usleep(400_000)
        }
        if target.exists { target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap(); return }
        XCTFail("Could not tap button containing \(text)")
    }

    private func save(_ name: String) {
        let out = ProcessInfo.processInfo.environment["BB_STORYALERT_SHOT_DIR"]
            ?? "/Users/chenmingming/Documents/Claude code/BudgetBuddy-StoryAlert-Screenshots"
        let dir = URL(fileURLWithPath: out, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: dir.appendingPathComponent("\(name).png"), options: .atomic)
    }
}
