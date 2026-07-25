import XCTest

final class Build13EnglishContentProbeUITests: XCTestCase {
    private var app: XCUIApplication!

    private var outputDirectory: URL {
        URL(
            fileURLWithPath: ProcessInfo.processInfo.environment["BUILD13_ENGLISH_SCREENSHOT_DIR"]
                ?? "/tmp/budgetbuddy-build13-english",
            isDirectory: true
        )
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        app = XCUIApplication()
        app.launchArguments = ["--build13-english-content-probe"]
        app.launch()
    }

    func testEnglishStoryIntroProbeStopsOnChineseIntro() throws {
        try reachEnglishReviewSession()
        XCTAssertTrue(waitForText("TODAY'S STORY", timeout: 20), "Home did not load in English")
        XCTAssertTrue(waitForText("The One-Month Budget Challenge", timeout: 5), "Home hero title is not English")
        XCTAssertTrue(waitForText("This month", timeout: 5) || waitForText("¥1000", timeout: 1), "Home hero description missing")
        try saveScreenshot("01-home-english-hero")

        tapTab("Stories")
        XCTAssertTrue(waitForText("INTERACTIVE STORIES", timeout: 10), "Stories tab did not load in English")
        XCTAssertTrue(waitForText("The One-Month Budget Challenge", timeout: 3), "Story path title is not English")
        try saveScreenshot("02-stories-path-top")

        tapText(containing: "The One-Month Budget Challenge")
        XCTAssertTrue(waitForText("The One-Month Budget Challenge", timeout: 8), "Story detail did not open")
        try saveScreenshot("03-month-life-intro")

        XCTAssertFalse(
            waitForText("这个月有 ¥1000", timeout: 1)
                || waitForText("新的一个月", timeout: 0.5)
                || waitForText("生活费", timeout: 0.5),
            "FAIL: English mode story intro/detail still contains Chinese copy before starting the story"
        )
    }

    private func reachEnglishReviewSession() throws {
        if app.buttons["English"].waitForExistence(timeout: 6) {
            app.buttons["English"].tap()
        } else if waitForText("Choose Your Language", timeout: 1) {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.69)).tap()
        }
        if app.buttons["Skip"].waitForExistence(timeout: 4) {
            app.buttons["Skip"].tap()
        } else if app.buttons["跳过"].waitForExistence(timeout: 1) {
            app.buttons["跳过"].tap()
        } else if waitForText("Get started", timeout: 1) || waitForText("Practice money choices", timeout: 1) {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.075)).tap()
        }

        if mainAppVisible(timeout: 8) {
            return
        }

        XCTAssertTrue(loginVisible(timeout: 12), "Login screen did not appear")
        let idField = app.textFields["Phone or email"].exists
            ? app.textFields["Phone or email"]
            : (app.textFields["手机号或邮箱"].exists ? app.textFields["手机号或邮箱"] : app.textFields.element(boundBy: 0))
        XCTAssertTrue(idField.waitForExistence(timeout: 5), "Missing identifier field")
        idField.tap()
        idField.typeText("review@budgetbuddy.cn")

        let passwordField = app.secureTextFields["Password"].exists
            ? app.secureTextFields["Password"]
            : (app.secureTextFields["密码"].exists ? app.secureTextFields["密码"] : app.secureTextFields.element(boundBy: 0))
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5), "Missing password field")
        passwordField.tap()
        passwordField.typeText(ProcessInfo.processInfo.environment["BB_REVIEW_PASSWORD"] ?? "")

        tapButton(containing: "Log in")
        dismissSavePasswordPromptIfNeeded()
        XCTAssertTrue(mainAppVisible(timeout: 35), "Review login did not reach main app")
    }

    private func loginVisible(timeout: TimeInterval) -> Bool {
        waitForText("Welcome back", timeout: timeout)
            || waitForText("欢迎回来", timeout: 0.5)
            || app.textFields["Phone or email"].waitForExistence(timeout: 0.5)
    }

    private func mainAppVisible(timeout: TimeInterval) -> Bool {
        waitForText("TODAY'S STORY", timeout: timeout)
            || waitForText("今 日 故 事", timeout: 0.5)
            || waitForText("BUDGETBUDDY", timeout: 0.5)
    }

    private func dismissSavePasswordPromptIfNeeded() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.buttons["Not Now"].waitForExistence(timeout: 4) {
            springboard.buttons["Not Now"].tap()
        } else if springboard.buttons["以后"].waitForExistence(timeout: 1) {
            springboard.buttons["以后"].tap()
        }
    }

    private func tapTab(_ label: String) {
        if app.tabBars.buttons[label].waitForExistence(timeout: 5) {
            app.tabBars.buttons[label].tap()
            return
        }
        tapButton(containing: label)
    }

    private func tapText(containing text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.staticTexts.matching(predicate).firstMatch
        XCTAssertTrue(target.waitForExistence(timeout: 6), "Could not find text \(text)")
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func tapButton(containing text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let button = app.buttons.matching(predicate).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 8), "Missing button containing \(text)")
        button.tap()
    }

    private func waitForText(_ text: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.matching(predicate).firstMatch.waitForExistence(timeout: timeout)
            || app.buttons.matching(predicate).firstMatch.waitForExistence(timeout: 0.2)
    }

    private func saveScreenshot(_ name: String) throws {
        try XCUIScreen.main.screenshot().pngRepresentation
            .write(to: outputDirectory.appendingPathComponent("\(name).png"))
    }
}
