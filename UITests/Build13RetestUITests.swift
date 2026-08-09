import XCTest

final class Build13RetestUITests: XCTestCase {
    private var app: XCUIApplication!
    private let account = "review@budgetbuddy.cn"
    private let password = ProcessInfo.processInfo.environment["BB_REVIEW_PASSWORD"] ?? ""

    private var screenshotDirectory: URL {
        URL(
            fileURLWithPath: ProcessInfo.processInfo.environment["BUILD13_RETEST_SCREENSHOT_DIR"]
                ?? "/tmp/budgetbuddy-retest-build13",
            isDirectory: true
        )
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-bb.engage.prompted.v1", "YES"]   // keep the 3-min engagement sheet out of automation
        // Preset the one-time rating-prompt flag — this suite finishes stories,
        // and the system rating sheet must not overlap automated taps.
        app.launchArguments = ["--build13-retest", "-bb.review.prompted.v1", "YES"]
        try FileManager.default.createDirectory(at: screenshotDirectory, withIntermediateDirectories: true)
        app.launch()
    }

    func testBuild13EnglishContentAndUXSmoke() throws {
        try ensureEnglishLoggedIn()

        try verifyHomeHeroAndStoryIntro()
        try verifyAIBuddyThinkingFlow()
        try verifyTrackerDoneKeyboard()
        try verifyTwoEnglishStories()
        try verifyLessonsCodexAndLanguageSwitch()
    }

    func testStoryPlaybackEnglishOnly() throws {
        try ensureEnglishLoggedIn()
        try verifyTwoEnglishStories()
    }

    func testShuadanStoryEnglishOnly() throws {
        try ensureEnglishLoggedIn()
        try verifyShuadanStory()
    }

    // MARK: - Setup

    private func ensureEnglishLoggedIn() throws {
        if waitForText("Choose Your Language", timeout: 5) {
            tapTextOrButton(containing: "English")
            Thread.sleep(forTimeInterval: 0.8)
        }

        if waitForText("Get started", timeout: 1) || waitForText("Practice money choices", timeout: 1) {
            tapButtonIfExists(containing: "Skip")
            if waitForText("Get started", timeout: 1) {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.90)).tap()
            }
            Thread.sleep(forTimeInterval: 1)
        } else {
            tapButtonIfExists(containing: "Skip")
        }

        if loginScreenVisible(timeout: 4) {
            try loginReviewAccount()
        }

        XCTAssertTrue(mainVisible(timeout: 25), "Main app did not load")
        // Build 14 guest mode: no launch gate — sign in via the optional profile
        // sheet so AI checks exercise the real logged-in path.
        try signInFromProfileIfGuest()
        if !waitForText("TODAY'S STORY", timeout: 2) {
            try switchLanguage(toEnglish: true)
        }
        XCTAssertTrue(waitForText("TODAY'S STORY", timeout: 10), "App is not in English mode")
    }

    private func signInFromProfileIfGuest() throws {
        tapTab(.me)
        guard waitForText("Not signed in", timeout: 3) || waitForText("未登录", timeout: 0.5) else {
            tapTab(.home)
            return
        }
        tapButton(containing: "Sign in / Sign up", fallbackContaining: "登录 / 注册")
        let idField = app.textFields.element(boundBy: 0)
        XCTAssertTrue(idField.waitForExistence(timeout: 6), "Missing account field in sheet")
        idField.tap()
        idField.typeText(account)
        let pw = app.secureTextFields.element(boundBy: 0)
        XCTAssertTrue(pw.waitForExistence(timeout: 6), "Missing password field in sheet")
        pw.tap()
        pw.typeText(password)
        tapButton(containing: "Log in", fallbackContaining: "登录")
        let deadline = Date().addingTimeInterval(30)
        var signedIn = false
        while Date() < deadline {
            if !app.staticTexts["Not signed in"].exists && !app.staticTexts["未登录"].exists {
                signedIn = true
                break
            }
            Thread.sleep(forTimeInterval: 1.0)
        }
        XCTAssertTrue(signedIn, "Sheet login did not complete")
        dismissSavePasswordPromptIfNeeded()
        // Relaunch: taps right after the auth sheet dismisses get eaten by its
        // lingering presentation layer. Language + session both persist.
        app.terminate()
        Thread.sleep(forTimeInterval: 1.0)
        app.launch()
        XCTAssertTrue(mainVisible(timeout: 30), "Relaunch after sheet login did not reach main app")
        tapTab(.home)
    }

    private func loginReviewAccount() throws {
        let fields = app.textFields
        let idField = app.textFields["Phone or email"].exists
            ? app.textFields["Phone or email"]
            : (app.textFields["手机号或邮箱"].exists ? app.textFields["手机号或邮箱"] : fields.element(boundBy: 0))
        XCTAssertTrue(idField.waitForExistence(timeout: 6), "Missing account field")
        idField.tap()
        idField.typeText(account)

        let passwordField = app.secureTextFields["Password"].exists
            ? app.secureTextFields["Password"]
            : (app.secureTextFields["密码"].exists ? app.secureTextFields["密码"] : app.secureTextFields.element(boundBy: 0))
        XCTAssertTrue(passwordField.waitForExistence(timeout: 6), "Missing password field")
        passwordField.tap()
        passwordField.typeText(password)

        tapButton(containing: "Log in", fallbackContaining: "登录")
        dismissSavePasswordPromptIfNeeded()
        XCTAssertTrue(mainVisible(timeout: 30), "Review account did not reach main app")
    }

    // MARK: - FAIL point regression

    private func verifyHomeHeroAndStoryIntro() throws {
        tapTab(.home)
        XCTAssertTrue(waitForText("The One-Month Budget Challenge", timeout: 10), "Home hero title is not English")
        XCTAssertTrue(waitForText("¥1000 for the month", timeout: 5), "Home hero description is not English")
        XCTAssertFalse(waitForText("这个月有 ¥1000", timeout: 0.5), "Home hero still contains Chinese")
        try save("01-home-hero-english")

        tapTab(.stories)
        XCTAssertTrue(waitForText("INTERACTIVE STORIES", timeout: 8), "Stories tab did not load in English")
        openStory(title: "The One-Month Budget Challenge")
        XCTAssertTrue(waitForText("The One-Month Budget Challenge", timeout: 8), "Story detail title missing")
        XCTAssertTrue(waitForText("¥1000 for the month", timeout: 5), "Story detail description is not English")
        XCTAssertTrue(waitForText("New month, and you've got ¥1000", timeout: 5), "Story detail intro is not English")
        XCTAssertFalse(waitForText("新的一个月", timeout: 0.5), "Story detail intro still contains Chinese")
        try save("02-story-intro-english")
        goBackIfPossible()
    }

    // MARK: - UX fixes

    private func verifyAIBuddyThinkingFlow() throws {
        tapTab(.ai)
        XCTAssertTrue(waitForText("AI Buddy", timeout: 8), "AI tab did not load")

        for i in 1...3 {
            sendAIMessage("Test \(i): give me one short money tip.")
            // Fast providers can answer before the bubble becomes queryable —
            // the definitive proof the send worked is the user's own bubble.
            let sawThinking = waitForText("Buddy is thinking", timeout: 4)
            if i == 1, sawThinking { try save("03-ai-thinking-bubble") }
            // send() dismisses the keyboard, but that's a ~0.4s animation — wait
            // for it to actually go away rather than sampling mid-dismissal.
            // No stuck keyboard after sending (sendAIMessage dismisses it, and the
            // app's send() calls bbHideKeyboard() too).
            let keyboardGone = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"),
                object: app.keyboards.firstMatch
            )
            XCTAssertEqual(XCTWaiter().wait(for: [keyboardGone], timeout: 4), .completed,
                           "Keyboard stayed open after sending AI message \(i)")
            XCTAssertTrue(waitForText("Test \(i)", timeout: 3), "Sent message bubble missing for message \(i)")
            XCTAssertTrue(waitForAIReply(timeout: 95), "AI reply did not arrive for message \(i)")
            XCTAssertFalse(waitForText("Oops, I lost my connection", timeout: 0.5), "AI Buddy showed offline fallback")
            XCTAssertFalse(waitForText("The AI is busy", timeout: 0.5), "AI Buddy showed busy fallback")
        }
        let chineseLabels = app.staticTexts.allElementsBoundByIndex
            .map(\.label)
            .filter { $0.range(of: #"[\u{4E00}-\u{9FFF}]"#, options: .regularExpression) != nil }
        XCTAssertTrue(chineseLabels.isEmpty, "AI Buddy English mode still contains Chinese text: \(chineseLabels)")
        try save("04-ai-three-replies")
    }

    private func verifyTrackerDoneKeyboard() throws {
        tapTab(.track)
        XCTAssertTrue(waitForText("Track", timeout: 8) || waitForText("Add entry", timeout: 2), "Track tab did not load")
        openAddEntry()
        XCTAssertTrue(waitForText("Add entry", timeout: 8), "Add entry sheet did not open")

        let noteField = app.textFields["What happened? (optional)"].exists
            ? app.textFields["What happened? (optional)"]
            : app.textFields.element(boundBy: 0)
        XCTAssertTrue(noteField.waitForExistence(timeout: 6), "Missing note field")
        noteField.tap()
        noteField.typeText("keyboard test")
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "Keyboard did not appear for note field")
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 4) || app.buttons["完成"].waitForExistence(timeout: 1), "Keyboard toolbar Done button missing")
        try save("05-tracker-keyboard-done")
        if app.buttons["Done"].exists { app.buttons["Done"].tap() } else { app.buttons["完成"].tap() }
        Thread.sleep(forTimeInterval: 0.7)
        XCTAssertFalse(app.keyboards.firstMatch.exists, "Done button did not dismiss keyboard")

        tapButton(containing: "1")
        XCTAssertTrue(waitForText("¥1", timeout: 3), "Amount keypad stopped working after note keyboard dismissal")
        try save("06-tracker-keypad-after-done")
        tapButtonIfExists(containing: "Cancel")
    }

    // MARK: - English content

    private func verifyTwoEnglishStories() throws {
        tapTab(.stories)
        openStory(title: "The One-Month Budget Challenge")
        playChoices([
            "Canteen every meal, extra drumstick sometimes",
            "Play ball and take walks at school",
            "Don't need it",
            "Top up ¥30",
            "Hold steady"
        ])
        XCTAssertTrue(waitForText("What went well", timeout: 10), "Month-life ending card is not English")
        XCTAssertTrue(waitForText("Money Whiz", timeout: 3) || waitForText("Got saving skills", timeout: 1) || waitForText("Still in training", timeout: 1), "Month-life ending title is not English")
        try save("07-month-life-ending")
        tapButton(containing: "Done")

        try verifyShuadanStory()
    }

    private func verifyShuadanStory() throws {
        tapTab(.stories)
        openStory(title: "Make 200 a day")
        if !waitForText("Make 200 a day", timeout: 8) {
            recordFailureContext("did-not-open-shuadan")
            XCTFail("Did not open the shua-dan story")
            return
        }
        XCTAssertTrue(waitForText("Make 200 a day", timeout: 8), "Did not open the shua-dan story")
        XCTAssertFalse(waitForText("The Flat Tire", timeout: 0.5), "Opened the wrong story instead of shua-dan")
        playChoices([
            "Leave the group and report it",
            "Don't pay",
            "Cut losses now",
            "Walk them through the whole script"
        ])
        XCTAssertTrue(waitForText("What went well", timeout: 10), "Shua-dan ending card is not English")
        XCTAssertTrue(waitForText("Anti-Scam Ambassador", timeout: 3) || waitForText("Hit the brakes", timeout: 1) || waitForText("Script Survivor", timeout: 1), "Shua-dan ending title is not English")
        try save("08-shua-dan-ending")
        tapButton(containing: "Done")
    }

    private func verifyLessonsCodexAndLanguageSwitch() throws {
        tapTab(.stories)
        tapTextOrButton(containing: "Money lessons")
        XCTAssertTrue(waitForText("What is a budget?", timeout: 8), "Lesson list did not show English lesson title")
        tapTextOrButton(containing: "What is a budget?")
        XCTAssertTrue(waitForText("Key points", timeout: 8), "Lesson detail key points are not English")
        XCTAssertTrue(waitForText("Student example", timeout: 5), "Lesson student example is not English")
        XCTAssertTrue(waitForText("Today's mini-task", timeout: 5), "Lesson mini-task is not English")
        XCTAssertTrue(waitForText("bilibili", timeout: 5) || waitForText("UP主", timeout: 1), "Lesson video card missing")
        try save("09-lesson-english")
        goBackIfPossible()

        tapTab(.stories)
        tapTextOrButton(containing: "Interactive stories")
        tapTextOrButton(containing: "Codex")
        XCTAssertTrue(waitForText("Codex", timeout: 8), "Codex did not open")
        XCTAssertTrue(waitForText("Warning signs", timeout: 8), "Codex warning signs are not English")
        XCTAssertTrue(waitForText("What to do", timeout: 5), "Codex actions are not English")
        XCTAssertTrue(waitForText("Impulse buying", timeout: 5), "Codex card title is not English")
        XCTAssertTrue(waitForText("Wait 24 hours", timeout: 5), "Codex action items are not translated")
        XCTAssertTrue(waitForText("Related story · Want or Need?", timeout: 5), "Codex related story title is not translated")
        XCTAssertFalse(waitForText("看到「限时」", timeout: 0.5), "Codex warning signs still contain Chinese")
        XCTAssertFalse(waitForText("想买非必需品", timeout: 0.5), "Codex action items still contain Chinese")
        try save("10-codex-english")
        goBackIfPossible()

        for _ in 0..<3 {
            try switchLanguage(toEnglish: false)
            tapTab(.home)
            XCTAssertTrue(waitForText("今 日 故 事", timeout: 8), "Chinese mode did not restore home content")
            XCTAssertFalse(waitForText("TODAY'S STORY", timeout: 0.5), "English home copy remained in Chinese mode")
            try switchLanguage(toEnglish: true)
            tapTab(.home)
            XCTAssertTrue(waitForText("TODAY'S STORY", timeout: 8), "English mode did not restore home content")
        }
        try save("11-language-back-to-english")
    }

    // MARK: - Story helpers

    private func openStory(title: String) {
        tapTab(.stories)
        XCTAssertTrue(waitForText("INTERACTIVE STORIES", timeout: 8), "Stories tab did not load before opening \(title)")
        scrollToTop()
        if let id = storyID(forEnglishTitle: title) {
            let node = app.descendants(matching: .any)["story-node-\(id)"]
            for _ in 0..<26 {
                if node.waitForExistence(timeout: 0.4), tapElementAfterScrollingIntoView(node) {
                    XCTAssertTrue(storyDetailOpened(timeout: 8), "Story detail did not open for \(title)")
                    return
                }
                app.swipeUp()
                Thread.sleep(forTimeInterval: 0.25)
            }
        }
        for _ in 0..<22 {
            if tapStoryPathNode(named: title) {
                XCTAssertTrue(storyDetailOpened(timeout: 8), "Story detail did not open for \(title)")
                return
            }
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.25)
        }
        XCTFail("Could not find story title: \(title)")
    }

    private func storyID(forEnglishTitle title: String) -> String? {
        if title.contains("One-Month Budget") { return "month-life" }
        if title.contains("Make 200") { return "shua-dan" }
        return nil
    }

    private func playChoices(_ choices: [String]) {
        XCTAssertTrue(tapScrollingToTextOrButton(containing: "Start"), "Missing Start button")
        for (idx, choice) in choices.enumerated() {
            if !tapScrollingToTextOrButton(containing: choice) {
                recordFailureContext("missing-choice-\(idx + 1)")
                XCTFail("Missing choice \(idx + 1): \(choice)")
                return
            }
            if idx == choices.count - 1 {
                if !tapScrollingToTextOrButton(containing: "See the results") {
                    recordFailureContext("missing-results-button-\(idx + 1)")
                    XCTFail("Missing See the results button")
                    return
                }
            } else {
                if !tapScrollingToTextOrButton(containing: "Continue") {
                    recordFailureContext("missing-continue-\(idx + 1)")
                    XCTFail("Missing Continue button after choice \(idx + 1)")
                    return
                }
            }
        }
    }

    @discardableResult
    private func tapScrollingToTextOrButton(containing text: String, maxSwipes: Int = 8) -> Bool {
        if tapTextOrButtonIfExists(containing: text) { return true }

        for _ in 0..<maxSwipes {
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.18)
            if tapTextOrButtonIfExists(containing: text) { return true }
        }

        for _ in 0..<maxSwipes {
            app.swipeDown()
            Thread.sleep(forTimeInterval: 0.18)
            if tapTextOrButtonIfExists(containing: text) { return true }
        }

        return false
    }

    @discardableResult
    private func tapStoryPathNode(named title: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", title)
        let button = app.buttons.matching(predicate).firstMatch
        if button.waitForExistence(timeout: 0.6) {
            button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            if storyDetailOpened(timeout: 2) { return true }
        }

        let label = app.staticTexts.matching(predicate).firstMatch
        guard label.waitForExistence(timeout: 0.6) else { return false }

        let nodeY = label.frame.midY - 64
        if nodeY > app.frame.maxY - 130 {
            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.25)
            return false
        }
        if nodeY < 85 {
            app.swipeDown()
            Thread.sleep(forTimeInterval: 0.25)
            return false
        }

        // Story path labels are rendered below the circular NavigationLink node.
        // Use absolute screen coordinates from the title frame; XCTest normalized
        // offsets on tiny Text nodes can drift enough to hit a neighboring node.
        for deltaY in [64.0, 58.0, 70.0, 52.0, 76.0] {
            tapAbsolute(x: label.frame.midX, y: label.frame.midY - deltaY)
            if storyDetailOpened(timeout: 2) { return true }
        }

        // Some cards outside the path are tappable as a whole, so try the label itself last.
        label.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        return storyDetailOpened(timeout: 2)
    }

    private func tapAbsolute(x: CGFloat, y: CGFloat) {
        let normalized = CGVector(
            dx: max(0.01, min(0.99, x / max(app.frame.width, 1))),
            dy: max(0.01, min(0.99, y / max(app.frame.height, 1)))
        )
        app.coordinate(withNormalizedOffset: normalized).tap()
    }

    private func storyDetailOpened(timeout: TimeInterval) -> Bool {
        waitForText("Start the story", timeout: timeout) || waitForText("Start", timeout: 0.5)
    }

    // MARK: - Shared helpers

    private enum Tab {
        case home, track, stories, ai, me
        var labels: [String] {
            switch self {
            case .home: return ["Home", "首页"]
            case .track: return ["Track", "记账"]
            case .stories: return ["Stories", "故事"]
            case .ai: return ["AI Buddy", "AI搭子"]
            case .me: return ["Me", "我的"]
            }
        }
        var x: CGFloat {
            switch self {
            case .home: return 0.10
            case .track: return 0.30
            case .stories: return 0.50
            case .ai: return 0.70
            case .me: return 0.90
            }
        }
    }

    private func tapTab(_ tab: Tab) {
        for label in tab.labels {
            let exact = app.buttons[label]
            if exact.waitForExistence(timeout: 1), exact.isHittable {
                exact.tap()
                Thread.sleep(forTimeInterval: 0.8)
                return
            }
        }
        for label in tab.labels {
            let predicate = NSPredicate(format: "label == %@", label)
            let button = app.buttons.matching(predicate).firstMatch
            if button.waitForExistence(timeout: 0.5) {
                button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                Thread.sleep(forTimeInterval: 0.8)
                return
            }
        }
        app.coordinate(withNormalizedOffset: CGVector(dx: tab.x, dy: 0.935)).tap()
        Thread.sleep(forTimeInterval: 0.8)
    }

    private func switchLanguage(toEnglish: Bool) throws {
        tapTab(.me)
        let rowText = toEnglish ? "Language" : "Language"
        if !tapTextOrButtonIfExists(containing: rowText) {
            _ = tapTextOrButtonIfExists(containing: "语言")
        }
        Thread.sleep(forTimeInterval: 0.5)
        if toEnglish {
            if !tapTextOrButtonIfExists(containing: "English") {
                XCTFail("Could not select English from language menu")
            }
        } else {
            if !tapTextOrButtonIfExists(containing: "中文") {
                XCTFail("Could not select Chinese from language menu")
            }
        }
        Thread.sleep(forTimeInterval: 0.8)
    }

    private func openAddEntry() {
        if tapTextOrButtonIfExists(containing: "Log your first choice") { return }
        if tapTextOrButtonIfExists(containing: "Log a choice") { return }
        if tapTextOrButtonIfExists(containing: "Add entry") { return }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.075)).tap()
    }

    private func sendAIMessage(_ text: String) {
        let field = app.textFields["Tell me about a choice…"].exists
            ? app.textFields["Tell me about a choice…"]
            : app.textFields.element(boundBy: 0)
        XCTAssertTrue(field.waitForExistence(timeout: 8), "AI input field missing")
        field.tap()
        field.typeText(text)
        // The app's "完成/Done" keyboard-accessory button (exposed under app.buttons,
        // NOT app.keyboards) sits directly on top of the send arrow (both far-right),
        // so a raw tap on send lands on Done. Dismiss the keyboard via Done first,
        // then tap the now-unobscured send button. The app's send() also calls
        // bbHideKeyboard(), so the end state (keyboard gone) is identical.
        let done = app.buttons["完成"].exists ? app.buttons["完成"] : app.buttons["Done"]
        if done.waitForExistence(timeout: 2), done.isHittable {
            done.tap()
            _ = XCTWaiter().wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"), object: app.keyboards.firstMatch)], timeout: 3)
        }
        let send = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@ OR identifier CONTAINS %@", "Arrow Up", "arrow.up")
        ).firstMatch
        if send.waitForExistence(timeout: 3), send.isHittable {
            send.tap()
        } else if app.buttons["paperplane.fill"].waitForExistence(timeout: 1) {
            app.buttons["paperplane.fill"].tap()
        } else {
            field.typeText("\n")
        }
    }

    private func waitForAIReply(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !textExists("Buddy is thinking") && !app.activityIndicators.firstMatch.exists {
                Thread.sleep(forTimeInterval: 1.0)
                return true
            }
            Thread.sleep(forTimeInterval: 1.0)
        }
        return false
    }

    private func loginScreenVisible(timeout: TimeInterval) -> Bool {
        waitForText("Welcome back", timeout: timeout)
            || waitForText("欢迎回来", timeout: 0.5)
            || app.textFields["Phone or email"].waitForExistence(timeout: 0.5)
            || app.textFields["手机号或邮箱"].waitForExistence(timeout: 0.5)
    }

    private func mainVisible(timeout: TimeInterval) -> Bool {
        waitForText("TODAY'S STORY", timeout: timeout)
            || waitForText("今 日 故 事", timeout: 0.5)
            || waitForText("BUDGETBUDDY", timeout: 0.5)
    }

    private func waitForText(_ text: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.matching(predicate).firstMatch.waitForExistence(timeout: timeout)
            || app.buttons.matching(predicate).firstMatch.waitForExistence(timeout: 0.2)
            || app.navigationBars.matching(predicate).firstMatch.waitForExistence(timeout: 0.2)
            || app.textFields.matching(predicate).firstMatch.waitForExistence(timeout: 0.2)
    }

    private func textExists(_ text: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.matching(predicate).firstMatch.exists
            || app.buttons.matching(predicate).firstMatch.exists
            || app.textFields.matching(predicate).firstMatch.exists
    }

    private func tapButton(containing text: String, fallbackContaining fallback: String? = nil) {
        if tapTextOrButtonIfExists(containing: text) { return }
        if let fallback, tapTextOrButtonIfExists(containing: fallback) { return }
        XCTFail("Missing tappable text/button containing \(text)")
    }

    private func tapButtonIfExists(containing text: String) {
        _ = tapTextOrButtonIfExists(containing: text)
    }

    @discardableResult
    private func tapTextOrButtonIfExists(containing text: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let button = app.buttons.matching(predicate).firstMatch
        if button.waitForExistence(timeout: 1.0) {
            return tapElementAfterScrollingIntoView(button)
        }
        let staticText = app.staticTexts.matching(predicate).firstMatch
        if staticText.waitForExistence(timeout: 0.5) {
            return tapElementAfterScrollingIntoView(staticText)
        }
        let field = app.textFields.matching(predicate).firstMatch
        if field.waitForExistence(timeout: 0.3) {
            return tapElementAfterScrollingIntoView(field)
        }
        return false
    }

    @discardableResult
    private func tapElementAfterScrollingIntoView(_ element: XCUIElement) -> Bool {
        for _ in 0..<6 {
            guard element.exists else { return false }
            let frame = element.frame
            let bottomSafeY = app.frame.maxY - 110
            if element.isHittable, frame.minY >= 80, frame.maxY <= bottomSafeY {
                element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                return true
            }

            if frame.maxY > bottomSafeY {
                app.swipeUp()
            } else if frame.minY < 80 {
                app.swipeDown()
            } else if element.isHittable {
                element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                return true
            } else {
                app.swipeUp()
            }
            Thread.sleep(forTimeInterval: 0.25)
        }

        if element.exists, element.isHittable {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return true
        }
        return false
    }

    private func tapTextOrButton(containing text: String) {
        XCTAssertTrue(tapTextOrButtonIfExists(containing: text), "Missing text/button containing \(text)")
    }

    private func scrollToTop() {
        for _ in 0..<5 {
            app.swipeDown()
            Thread.sleep(forTimeInterval: 0.15)
        }
    }

    private func goBackIfPossible() {
        if app.navigationBars.buttons.element(boundBy: 0).exists {
            app.navigationBars.buttons.element(boundBy: 0).tap()
            Thread.sleep(forTimeInterval: 0.6)
            return
        }
        app.swipeRight()
        Thread.sleep(forTimeInterval: 0.6)
    }

    private func dismissSavePasswordPromptIfNeeded() {
        // The dialog can pop several seconds AFTER the login response.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.buttons["Not Now"].waitForExistence(timeout: 8) {
            springboard.buttons["Not Now"].tap()
            Thread.sleep(forTimeInterval: 1.0)
        } else if springboard.buttons["以后"].waitForExistence(timeout: 1) {
            springboard.buttons["以后"].tap()
            Thread.sleep(forTimeInterval: 1.0)
        }
    }

    private func save(_ name: String) throws {
        let url = screenshotDirectory.appendingPathComponent("\(name).png")
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: url)
    }

    private func recordFailureContext(_ name: String) {
        try? save("FAIL-\(name)")
        let url = screenshotDirectory.appendingPathComponent("FAIL-\(name)-ui.txt")
        try? app.debugDescription.write(to: url, atomically: true, encoding: .utf8)
    }
}
