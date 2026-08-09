import XCTest

// v1.5.1 content probe: the 8 new stories (guzi / card-live / fake-police /
// hongbao-fanli / hidden-bubble / dashang / bangxin / xianyong) must appear in
// the 故事 list, open, and play through real choices in both languages.
// Screenshots land in BB_NEWSTORY_SHOT_DIR (default below) for human review.
final class NewStoriesProbeUITests: XCTestCase {
    private var app: XCUIApplication!

    private let allNewIDs = [
        "guzi", "card-live", "fake-police", "hongbao-fanli",
        "hidden-bubble", "dashang", "bangxin", "xianyong",
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    // All 8 titles listed; three of them played into scene 2 with real choices.
    func testA_NewStoriesListedAndPlayableZH() throws {
        app.launch()
        ensureInApp()
        tapTab("故事")
        XCTAssertTrue(waitForText("互 动 故 事", timeout: 10), "Stories tab did not load")

        for id in allNewIDs {
            XCTAssertTrue(app.buttons["story-node-\(id)"].exists, "New story missing from list: \(id)")
        }
        XCTAssertTrue(scrollToNode("xianyong"), "Could not scroll the path down to the new stories")
        save("n1-list-bottom-with-new-stories")

        // ① guzi: intro → scene 1 → choice → consequence → scene 2
        openStory(node: "guzi", introContains: "谷子", shot: "n2-guzi-intro")
        tapButton(containing: "开始游戏")
        XCTAssertTrue(waitForText("同桌的痛包", timeout: 8), "guzi scene 1 missing")
        save("n3-guzi-scene1")
        tapButton(containing: "先想想")
        XCTAssertTrue(waitForText("怕跟不上", timeout: 6), "guzi choice tip missing")
        save("n4-guzi-consequence")
        tapButton(containing: "继续")
        XCTAssertTrue(waitForText("15 变 45", timeout: 8), "guzi scene 2 missing")
        save("n5-guzi-scene2")

        // ② fake-police: the anti-scam flow reacts correctly
        relaunchZH()
        tapTab("故事")
        openStory(node: "fake-police", introContains: "公检法", shot: "n6-fakepolice-intro")
        tapButton(containing: "开始游戏")
        XCTAssertTrue(waitForText("网安支队", timeout: 8), "fake-police scene 1 npc line missing")
        save("n7-fakepolice-scene1")
        tapButton(containing: "挂断")
        XCTAssertTrue(waitForText("这是诈骗", timeout: 6), "fake-police consequence missing")
        tapButton(containing: "继续")
        XCTAssertTrue(waitForText("保密", timeout: 8), "fake-police scene 2 missing")
        save("n8-fakepolice-scene2")

        // ③ xianyong: revised-graph sibling (4-scene story opens and starts)
        relaunchZH()
        tapTab("故事")
        openStory(node: "xianyong", introContains: "先用后付", shot: "n9-xianyong-intro")
        tapButton(containing: "开始游戏")
        XCTAssertTrue(waitForText("0 元下单", timeout: 8), "xianyong scene 1 missing")
        save("n10-xianyong-scene1")
    }

    // The revised subscribe story routes s3 → the new 短剧 scene (s3b) → s4.
    func testB_SubscribeDetourReachesShortDramaScene() throws {
        app.launch()
        ensureInApp()
        tapTab("故事")
        openStory(node: "subscribe", introContains: "订阅", shot: "n11-subscribe-intro")
        tapButton(containing: "开始游戏")
        for choice in ["把小字读完再决定", "当场取消自动续费", "只留每周都在用的那个"] {  // s1 → s2 → s3
            tapButton(containing: choice)
            sleep(1)
            tapButton(containing: "继续")
            sleep(1)
        }
        XCTAssertTrue(waitForText("9.9 元解锁全集", timeout: 10) || waitForText("每季单独收费", timeout: 2),
                      "subscribe did not route into the new 短剧 scene (s3b)")
        save("n12-subscribe-s3b-shortdrama")
    }

    // English pass: forced via NSArgumentDomain (-bb.lang en overrides the stored pref).
    func testC_NewStoriesEnglish() throws {
        app.launchArguments += ["-bb.lang", "en"]
        app.launch()
        ensureInApp()
        tapTab("Stories")
        XCTAssertTrue(waitForText("INTERACTIVE STORIES", timeout: 10), "EN stories tab did not load")
        XCTAssertTrue(app.buttons["story-node-guzi"].exists, "EN list missing guzi node")
        XCTAssertTrue(scrollToNode("dashang"), "EN path did not scroll to dashang")
        XCTAssertTrue(waitForText("The price of Top Fan", timeout: 4), "EN title for dashang missing")
        save("n13-en-list")
        openStory(node: "guzi", introContains: "anime merch", shot: "n14-en-guzi-intro")
        tapButton(containing: "Start")
        XCTAssertTrue(waitForText("ita bag", timeout: 8), "EN guzi scene 1 missing")
        save("n15-en-guzi-scene1")
    }

    // MARK: helpers

    private func openStory(node id: String, introContains: String, shot: String) {
        XCTAssertTrue(scrollToNode(id), "Story node not reachable: \(id)")
        usleep(500_000)
        app.buttons["story-node-\(id)"].tap()
        XCTAssertTrue(waitForText(introContains, timeout: 8), "Intro for \(id) missing text \(introContains)")
        save(shot)
    }

    private func scrollToNode(_ id: String) -> Bool {
        let target = app.buttons["story-node-\(id)"]
        let window = app.windows.firstMatch.frame
        for _ in 0..<50 {
            if target.exists && target.isHittable { return true }
            // The path is a plain (non-lazy) stack: nodes exist off-screen with a
            // real frame, so steer toward the target instead of swiping blindly.
            if target.exists && target.frame.midY < window.minY + 120 {
                app.swipeDown()
            } else {
                app.swipeUp()
            }
            usleep(350_000)
        }
        return target.exists && target.isHittable
    }

    private func relaunchZH() {
        app.terminate()
        app = XCUIApplication()
        app.launch()
        ensureInApp()
    }

    private func ensureInApp() {
        if app.staticTexts["选择语言"].waitForExistence(timeout: 3) {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "中文")).firstMatch.tap()
            sleep(1)
        }
        if app.buttons["跳过"].waitForExistence(timeout: 3) { app.buttons["跳过"].tap() }
        if app.buttons["Skip"].waitForExistence(timeout: 1) { app.buttons["Skip"].tap() }
        XCTAssertTrue(mainAppVisible(timeout: 15), "Did not reach the main app")
    }

    private func mainAppVisible(timeout: TimeInterval) -> Bool {
        waitForText("今 日 故 事", timeout: timeout)
            || waitForText("TODAY'S STORY", timeout: 0.5)
            || waitForText("本 周 概 览", timeout: 0.5)
    }

    private func tapTab(_ label: String) {
        let tabButton = app.tabBars.buttons[label].firstMatch
        if tabButton.waitForExistence(timeout: 2), tabButton.isHittable { tabButton.tap(); sleep(1); return }
        let anyButton = app.buttons[label].firstMatch
        if anyButton.waitForExistence(timeout: 2), anyButton.isHittable { anyButton.tap(); sleep(1); return }
        let x: CGFloat = (label == "故事" || label == "Stories") ? 0.50 : 0.10
        app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.965)).tap()
        sleep(1)
    }

    private func waitForText(_ text: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.matching(predicate).firstMatch.waitForExistence(timeout: timeout)
            || app.buttons.matching(predicate).firstMatch.waitForExistence(timeout: 0.2)
            || app.navigationBars.matching(predicate).firstMatch.waitForExistence(timeout: 0.2)
    }

    private func scrollToText(_ text: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.staticTexts.matching(predicate).firstMatch
        for _ in 0..<14 {
            if target.exists { return true }
            app.swipeUp()
            usleep(400_000)
        }
        return target.exists
    }

    private func tapButton(containing text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.buttons.matching(predicate).firstMatch
        for _ in 0..<10 {
            if target.exists && target.isHittable {
                usleep(500_000)
                if target.exists && target.isHittable { target.tap(); return }
            }
            app.swipeUp()
            usleep(400_000)
        }
        if target.exists {
            target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return
        }
        XCTFail("Could not tap button containing \(text)")
    }

    private func tapButtonIfExists(containing text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.buttons.matching(predicate).firstMatch
        if target.waitForExistence(timeout: 2), target.isHittable { target.tap() }
    }

    private func save(_ name: String) {
        let out = ProcessInfo.processInfo.environment["BB_NEWSTORY_SHOT_DIR"]
            ?? "/Users/chenmingming/Documents/Claude code/BudgetBuddy-NewStories-Screenshots"
        let dir = URL(fileURLWithPath: out, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? XCUIScreen.main.screenshot().pngRepresentation
            .write(to: dir.appendingPathComponent("\(name).png"), options: .atomic)
    }
}
