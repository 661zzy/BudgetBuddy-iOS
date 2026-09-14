import XCTest

// v1.6.2 反馈回复 — the whole user side against canned threads
// (`-bb.uitest.feedbackThreads`), so it runs offline and never touches the server:
// Home banner → conversation → follow-up → banner gone → 我的 → 我的反馈 list.
// The same flow against the real backend lives in FeedbackRepliesLiveUITests.
final class FeedbackRepliesUITests: XCTestCase {
    private var app: XCUIApplication!
    private let reply = "谢谢！1.6.1 已经可以自定义分类了，更新一下就能用。"
    private var outDir: URL {
        let p = ProcessInfo.processInfo.environment["BB_SITE_SHOT_DIR"]
            ?? "/Users/chenmingming/Documents/Claude code/BudgetBuddy-1.6.2-反馈回复/shots"
        let u = URL(fileURLWithPath: p, isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    private func stubJSON(lang: String) -> String {
        let now = Int(Date().timeIntervalSince1970)
        let original = lang == "en" ? "Could I rename 其他 to my own categories, like utilities and rent?" : "能不能把「其他」让用户自己编辑添加为新的名字，比如：水电，房租"
        let answer = lang == "en" ? "Thanks! Custom categories are in 1.6.1 — just update the app." : reply
        return """
        {"threads":[
          {"id":41,"message":"\(original)","imageCount":1,"status":"replied","createdAt":\(now - 86400),"updatedAt":\(now - 1800),"unread":1,
           "messages":[{"id":1,"author":"team","body":"\(answer)","createdAt":\(now - 1800)}]},
          {"id":38,"message":"快答第 3 题的答案好像不对","imageCount":0,"status":"closed","createdAt":\(now - 5 * 86400),"updatedAt":\(now - 4 * 86400),"unread":0,
           "messages":[{"id":2,"author":"team","body":"已经改好了，谢谢你！","createdAt":\(now - 4 * 86400)}]}
        ],"unread":1}
        """
    }

    private func launch(lang: String) {
        continueAfterFailure = false
        app = XCUIApplication()
        // One line, no apostrophes: the runner re-splits launch arguments like a shell would.
        let json = stubJSON(lang: lang).components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.joined()
        app.launchArguments += ["-bb.lang", lang, "-bb.engage.prompted.v1", "YES", "-bb.review.prompted.v1", "YES",
                                "-bb.uitest.feedbackThreads", json]
        app.launch()
        ensureInApp()
        shoot("0-launch-\(lang)")
    }

    func testA_ReplyBannerConversationAndFollowUp() throws {
        launch(lang: "zh")
        let banner = app.buttons["feedback.banner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 10), "reply banner missing on Home")
        XCTAssertTrue(banner.label.contains("你的反馈有新回复"), banner.label)
        shoot("1-home-banner")

        banner.tap()
        let team = app.descendants(matching: .any)["feedback.bubble.team"]
        XCTAssertTrue(team.waitForExistence(timeout: 6), "team reply bubble missing")
        XCTAssertTrue(app.staticTexts[reply].exists, "reply text not shown")
        shoot("2-thread")

        let composer = app.textFields["feedback.composer"].exists ? app.textFields["feedback.composer"] : app.textViews["feedback.composer"]
        XCTAssertTrue(composer.waitForExistence(timeout: 4), "composer missing")
        let send = app.buttons["feedback.composer.send"]
        XCTAssertFalse(send.isEnabled, "send enabled with an empty draft")
        composer.tap()
        composer.typeText("太好了，图标能再多一点吗")
        XCTAssertTrue(send.isEnabled)
        send.tap()
        XCTAssertTrue(app.staticTexts["太好了，图标能再多一点吗"].waitForExistence(timeout: 5), "follow-up bubble missing")
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "feedback.bubble.user").count, 2, "original + follow-up")
        shoot("3-follow-up")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(waitGone(banner, 5), "banner still there after reading the reply")

        tapTab("我的")
        let row = app.buttons["profile.feedback"]
        for _ in 0..<5 where !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertFalse(row.label.contains("新回复"), "profile row still says new reply: \(row.label)")
        row.tap()
        let thread41 = app.buttons["feedback.thread.41"]
        XCTAssertTrue(thread41.waitForExistence(timeout: 6), "我的反馈 list missing")
        XCTAssertTrue(thread41.label.contains("等待回复"), "follow-up should reopen the thread: \(thread41.label)")
        XCTAssertTrue(app.buttons["feedback.thread.38"].label.contains("已处理"))
        XCTAssertTrue(app.staticTexts["没登录时，回复只会显示在这台设备上。"].exists, "guest hint missing")
        shoot("4-my-feedback")
    }

    func testB_UnreadShowsOnProfileBeforeOpening() throws {
        launch(lang: "zh")
        tapTab("我的")
        let row = app.buttons["profile.feedback"]
        for _ in 0..<5 where !row.isHittable { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("1 条新回复"), row.label)
        shoot("5-profile-unread")
        row.tap()
        XCTAssertTrue(app.buttons["feedback.thread.41"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.staticTexts["1 条新回复"].exists, "section badge missing")
        shoot("6-feedback-page-unread")
    }

    func testC_English() throws {
        launch(lang: "en")
        let banner = app.buttons["feedback.banner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 10))
        XCTAssertTrue(banner.label.contains("New reply to your feedback"), banner.label)
        banner.tap()
        XCTAssertTrue(app.navigationBars["Conversation"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.staticTexts["BudgetBuddy team"].exists || app.descendants(matching: .any)["feedback.bubble.team"].label.contains("BudgetBuddy team"))
        shoot("7-thread-en")
    }

    // MARK: helpers

    private func shoot(_ name: String) {
        try? XCUIScreen.main.screenshot().pngRepresentation
            .write(to: outDir.appendingPathComponent("\(name).png"), options: .atomic)
    }

    private func ensureInApp() {
        if app.staticTexts["选择语言"].waitForExistence(timeout: 4) || app.staticTexts["Choose a language"].exists {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "中文")).firstMatch.tap(); sleep(1)
        }
        for l in ["跳过", "Skip"] where app.buttons[l].waitForExistence(timeout: 2) { app.buttons[l].tap(); break }
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 15)
    }

    private func tapTab(_ label: String) {
        let t = app.tabBars.buttons[label].firstMatch
        XCTAssertTrue(t.waitForExistence(timeout: 5), "tab \(label) missing")
        t.tap(); sleep(1)
    }

    private func waitGone(_ e: XCUIElement, _ timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while e.exists && Date() < deadline { usleep(200_000) }
        return !e.exists
    }
}
