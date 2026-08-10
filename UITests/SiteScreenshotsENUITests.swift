import XCTest

// Captures the English UI shots used by budgetbuddy.cn/en.html (the site had
// Chinese app screenshots on its English page). Runs the app forced to English
// via NSArgumentDomain. Tracking needs an account, so that one case skips
// unless BB_REVIEW_PASSWORD is provided (same pattern as GuestModeUITests).
final class SiteScreenshotsENUITests: XCTestCase {
    private var app: XCUIApplication!
    private let account = "review@budgetbuddy.cn"
    private let password = ProcessInfo.processInfo.environment["BB_REVIEW_PASSWORD"] ?? ""

    private var outDir: URL {
        let p = ProcessInfo.processInfo.environment["BB_SITE_SHOT_DIR"]
            ?? "/Users/chenmingming/Documents/Claude code/BudgetBuddy-site-shots-en"
        let u = URL(fileURLWithPath: p, isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-bb.lang", "en",
                                "-bb.engage.prompted.v1", "YES",
                                "-bb.review.prompted.v1", "YES"]
    }

    func testA_HomeEN() throws {
        app.launch()
        ensureInApp()
        XCTAssertTrue(waitForText("TODAY'S STORY", timeout: 12), "EN home did not render")
        sleep(1)
        shoot("app-home-en")
    }

    func testB_StoryEN() throws {
        app.launch()
        ensureInApp()
        tapTab("Stories")
        XCTAssertTrue(waitForText("INTERACTIVE STORIES", timeout: 10), "EN stories tab did not load")
        // Open the first story and start it, so the shot shows a real scene with choices.
        let node = app.buttons["story-node-month-life"]
        XCTAssertTrue(node.waitForExistence(timeout: 8), "First story node missing")
        node.tap()
        tapButton(containing: "Start")
        sleep(2)
        shoot("app-story-en")
    }

    func testC_TrackingEN() throws {
        try XCTSkipIf(password.isEmpty, "Set BB_REVIEW_PASSWORD to capture the tracking screen")
        app.launch()
        ensureInApp()
        tapTab("Me")
        if waitForText("Not signed in", timeout: 4) {
            tapButton(containing: "Sign in / Sign up")      // profile row
            XCTAssertTrue(waitForText("Welcome back", timeout: 8), "Auth sheet did not open")
            let idField = app.textFields["Phone or email"].exists
                ? app.textFields["Phone or email"] : app.textFields.element(boundBy: 0)
            XCTAssertTrue(idField.waitForExistence(timeout: 6), "Missing identifier field")
            idField.tap(); idField.typeText(account)
            let pw = app.secureTextFields.element(boundBy: 0)
            XCTAssertTrue(pw.waitForExistence(timeout: 5), "Missing password field")
            pw.tap(); pw.typeText(password)
            // The submit button is "Log in" (登录) — NOT "Sign in", which is only
            // the profile entry row. Tapping the wrong label silently does nothing
            // and the screenshot ends up being the auth sheet.
            app.buttons["Log in"].firstMatch.tap()
            XCTAssertTrue(waitForText("Review demo", timeout: 25) || waitForText("审核演示", timeout: 2),
                          "Login did not complete")
            dismissSavePasswordPromptIfNeeded()
        }
        tapTab("Track")
        // Prove we are really on the tracker before shooting, so a failed login
        // can never masquerade as a good marketing screenshot.
        let onTracker = waitForText("This month", timeout: 12) || waitForText("Expense", timeout: 3)
            || app.buttons["Add entry"].waitForExistence(timeout: 3)
            || waitForText("Sign in to start tracking", timeout: 1)
        if !onTracker { shoot("debug-tracker-state") }
        XCTAssertTrue(onTracker, "Tracker did not render — refusing to save a bogus screenshot")
        XCTAssertFalse(waitForText("Sign in to start tracking", timeout: 1),
                       "Still on the login gate — the session did not carry over")
        XCTAssertFalse(app.staticTexts["Welcome back"].exists, "Auth sheet still on screen")

        // NOTE: the Add-entry sheet would be the nicer marketing shot (pure UI
        // chrome, so fully English), but it would not open under automation —
        // neither the navbar "+" nor Home's "Log a choice" row presented it in
        // four attempts. Shipping the list instead: chrome is English, only the
        // review account's own entry titles are Chinese. The guards above stay,
        // so a failed login can still never masquerade as a good screenshot.
        sleep(2)
        shoot("app-reflect-en")
    }


    func testD_StoriesListEN() throws {
        app.launch()
        ensureInApp()
        tapTab("Stories")
        XCTAssertTrue(waitForText("INTERACTIVE STORIES", timeout: 10), "EN stories tab did not load")
        // Scroll down a touch so the path shows several English titles at once.
        app.swipeUp(); usleep(500_000)
        XCTAssertTrue(app.staticTexts["Want or Need?"].waitForExistence(timeout: 4)
                        || app.staticTexts["The Anti-Scam Battle"].exists,
                      "Stories list titles not in English")
        sleep(1)
        shoot("app-stories-list-en")
    }

    // MARK: helpers

    private func shoot(_ name: String) {
        let url = outDir.appendingPathComponent("\(name).png")
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: url, options: .atomic)
    }

    private func dismissSavePasswordPromptIfNeeded() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Not Now", "Save Password", "Never for This Website"] {
            let b = springboard.buttons[label]
            if b.waitForExistence(timeout: 3), b.isHittable { b.tap(); sleep(1); return }
        }
    }

    private func ensureInApp() {
        if app.staticTexts["Choose a language"].waitForExistence(timeout: 4)
            || app.staticTexts["选择语言"].exists {
            let en = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "English")).firstMatch
            if en.exists { en.tap() } else {
                app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "中文")).firstMatch.tap()
            }
            sleep(1)
        }
        for l in ["Skip", "跳过"] where app.buttons[l].waitForExistence(timeout: 2) {
            app.buttons[l].tap(); break
        }
        XCTAssertTrue(waitForText("TODAY'S STORY", timeout: 15) || waitForText("THIS WEEK", timeout: 1),
                      "Did not reach the main app in English")
    }

    private func tapTab(_ label: String) {
        let t = app.tabBars.buttons[label].firstMatch
        if t.waitForExistence(timeout: 2), t.isHittable { t.tap(); sleep(1); return }
        let b = app.buttons[label].firstMatch
        if b.waitForExistence(timeout: 2), b.isHittable { b.tap(); sleep(1); return }
        let x: CGFloat
        switch label {
        case "Home": x = 0.10
        case "Track": x = 0.30
        case "Stories": x = 0.50
        case "AI Buddy": x = 0.70
        default: x = 0.90
        }
        app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.965)).tap()
        sleep(1)
    }

    private func waitForText(_ text: String, timeout: TimeInterval) -> Bool {
        let p = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.matching(p).firstMatch.waitForExistence(timeout: timeout)
            || app.buttons.matching(p).firstMatch.waitForExistence(timeout: 0.2)
    }

    private func tapButton(containing text: String) {
        let p = NSPredicate(format: "label CONTAINS %@", text)
        let t = app.buttons.matching(p).firstMatch
        for _ in 0..<8 {
            if t.exists && t.isHittable { usleep(400_000); t.tap(); return }
            app.swipeUp(); usleep(350_000)
        }
        if t.exists { t.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() }
    }
}
