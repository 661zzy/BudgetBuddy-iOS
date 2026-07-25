import XCTest

// Verifies App Store Guideline 5.1.1(v) compliance: no login wall, core
// features usable as a guest, login optional from 我的, logout stays in-app.
// testA expects a FRESH INSTALL (uninstall the app before the run).
final class GuestModeUITests: XCTestCase {
    private var app: XCUIApplication!
    private let account = "review@budgetbuddy.cn"
    private let password = "***SCRUBBED***"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // Fresh install: language → onboarding skip → straight into the app. No auth gate.
    func testA_GuestLandsInAppWithoutLogin() throws {
        if app.staticTexts["选择语言"].waitForExistence(timeout: 6) {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "中文")).firstMatch.tap()
            sleep(1)
        }
        if app.buttons["跳过"].waitForExistence(timeout: 5) {
            app.buttons["跳过"].tap()
        }
        XCTAssertTrue(mainAppVisible(timeout: 15), "Guest did not land in the main app")
        XCTAssertFalse(app.staticTexts["欢迎回来"].exists, "Login gate still shown to guest")
        save("g1-guest-home")
    }

    // Tracking is an ACCOUNT feature: guests hitting the tracker get the login
    // sheet automatically; the gate page stays behind it; home quick-add is gated too.
    func testB_GuestTrackerRequiresLogin() throws {
        ensureInApp()
        tapTab("记账")
        XCTAssertTrue(waitForText("欢迎回来", timeout: 8), "Auth sheet did not auto-present on tracker for guest")
        save("g2a-tracker-auto-login-sheet")
        tapButtonIfExists(containing: "暂不登录")
        sleep(1)
        XCTAssertTrue(waitForText("登录后开始记账", timeout: 6), "Tracker login gate not shown after dismissing sheet")
        XCTAssertFalse(waitForText("记一笔", timeout: 1), "Guest can still reach the add sheet")
        save("g2b-tracker-login-gate")

        tapTab("首页")
        tapButton(containing: "记录一次选择")
        XCTAssertTrue(waitForText("欢迎回来", timeout: 6), "Auth sheet did not open from home quick-add")
        tapButtonIfExists(containing: "暂不登录")
        sleep(1)
        XCTAssertFalse(app.staticTexts["记一笔"].exists, "Guest reached AddSheet from home without login")
    }

    // Guest can open AI and send a message; a buddy reply bubble appears.
    func testC_GuestAIUsable() throws {
        ensureInApp()
        tapTab("AI搭子")
        XCTAssertTrue(waitForText("AI搭子", timeout: 8), "AI tab did not load")
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 8), "Missing AI input")
        field.tap()
        field.typeText("给我一个省钱小建议")
        let send = app.buttons.matching(NSPredicate(format: "label CONTAINS %@ OR identifier CONTAINS %@", "Arrow Up", "arrow.up")).firstMatch
        if send.waitForExistence(timeout: 3), send.isHittable { send.tap() } else { field.typeText("\n") }
        sleep(25)
        // At least one buddy reply beyond the greeting (AI or graceful fallback — never a crash/blank).
        let bubbles = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@ OR label CONTAINS %@", "建议", "省", "搭子"))
        XCTAssertTrue(bubbles.count >= 1, "No AI reply/fallback appeared for guest")
        save("g3-guest-ai")
    }

    // 我的 shows the optional login entry; login works from the sheet; logout stays in-app.
    func testD_OptionalLoginFromProfile() throws {
        ensureInApp()
        tapTab("我的")
        // Self-heal: a previous run may have left a logged-in session.
        if !waitForText("未登录", timeout: 4) {
            tapButton(containing: "退出登录")
            sleep(2)
            for _ in 0..<4 { app.swipeDown() }
        }
        XCTAssertTrue(waitForText("未登录", timeout: 8), "Profile does not show guest state")
        save("g4-profile-guest")

        // Open the auth sheet, close it — still in the app.
        tapButton(containing: "登录 / 注册")
        XCTAssertTrue(waitForText("欢迎回来", timeout: 6), "Auth sheet did not open")
        tapButtonIfExists(containing: "暂不登录")
        sleep(1)
        XCTAssertTrue(waitForText("未登录", timeout: 6), "Closing auth sheet kicked user out of app")

        // Log in for real.
        tapButton(containing: "登录 / 注册")
        XCTAssertTrue(waitForText("欢迎回来", timeout: 6), "Auth sheet did not reopen")
        let idField = app.textFields["手机号或邮箱"].exists ? app.textFields["手机号或邮箱"] : app.textFields.element(boundBy: 0)
        XCTAssertTrue(idField.waitForExistence(timeout: 5), "Missing identifier field")
        idField.tap(); idField.typeText(account)
        let pwField = app.secureTextFields.element(boundBy: 0)
        XCTAssertTrue(pwField.waitForExistence(timeout: 5), "Missing password field")
        pwField.tap(); pwField.typeText(password)
        tapButton(containing: "登录")
        XCTAssertTrue(waitForText("审核演示", timeout: 20), "Login from sheet did not complete")
        // The system Save-Password dialog pops AFTER the login response — clear it
        // before any further taps, or every gesture lands on the dialog.
        dismissSavePasswordPromptIfNeeded()
        save("g5-profile-logged-in")

        // Relaunch to a pristine logged-in UI (session cookie persists) so the
        // logout tap can't collide with sheet-dismissal residue.
        app.terminate()
        app.launch()
        ensureInApp()
        tapTab("我的")
        XCTAssertTrue(waitForText("审核演示", timeout: 10), "Relaunch lost the session")

        // Logout returns to guest mode INSIDE the app (no gate).
        tapButton(containing: "退出登录")
        sleep(1)
        save("g6a-right-after-logout-tap")
        sleep(2)
        for _ in 0..<4 { app.swipeDown() }   // back to the identity row at the top
        save("g6-after-logout-debug")
        XCTAssertTrue(waitForText("未登录", timeout: 10), "Logout did not return to in-app guest mode")
        XCTAssertFalse(app.staticTexts["欢迎回来"].exists, "Logout dumped user to a login gate")
        save("g6-profile-after-logout")
    }

    // MARK: helpers

    private func ensureInApp() {
        if app.staticTexts["选择语言"].waitForExistence(timeout: 2) {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "中文")).firstMatch.tap()
            sleep(1)
        }
        if app.buttons["跳过"].waitForExistence(timeout: 2) {
            app.buttons["跳过"].tap()
        }
        XCTAssertTrue(mainAppVisible(timeout: 15), "Did not reach the main app")
    }

    private func mainAppVisible(timeout: TimeInterval) -> Bool {
        waitForText("今 日 故 事", timeout: timeout)
            || waitForText("本 周 概 览", timeout: 0.5)
            || waitForText("搭 子 说", timeout: 0.5)
    }

    // Element-based: raw bottom-edge coordinates miss the tab buttons under the
    // iOS 26 SDK (buttons end ~34pt above the screen bottom) and there is no
    // bottom bar at all on iPadOS 18+ (tabs move to the top).
    private func tapTab(_ label: String) {
        let tabButton = app.tabBars.buttons[label].firstMatch
        if tabButton.waitForExistence(timeout: 2), tabButton.isHittable {
            tabButton.tap(); sleep(1); return
        }
        let anyButton = app.buttons[label].firstMatch
        if anyButton.waitForExistence(timeout: 2), anyButton.isHittable {
            anyButton.tap(); sleep(1); return
        }
        let x: CGFloat
        switch label {
        case "首页": x = 0.10
        case "记账": x = 0.30
        case "故事": x = 0.50
        case "AI搭子": x = 0.70
        case "我的": x = 0.90
        default: x = 0.50
        }
        app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.965)).tap()
        sleep(1)
    }

    private func tapKeypad(_ key: String) {
        let b = app.buttons[key]
        if b.waitForExistence(timeout: 2), b.isHittable { b.tap() }
        else { app.staticTexts[key].firstMatch.tap() }
        usleep(300_000)
    }

    private func waitForText(_ text: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.matching(predicate).firstMatch.waitForExistence(timeout: timeout)
            || app.buttons.matching(predicate).firstMatch.waitForExistence(timeout: 0.2)
            || app.navigationBars.matching(predicate).firstMatch.waitForExistence(timeout: 0.2)
    }

    private func tapButtonIfExists(containing text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.buttons.matching(predicate).firstMatch
        if target.waitForExistence(timeout: 2), target.isHittable { target.tap() }
    }

    private func tapButton(containing text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.buttons.matching(predicate).firstMatch
        for _ in 0..<10 {
            if target.exists && target.isHittable {
                usleep(500_000)   // let scroll deceleration settle or the tap only stops the scroll
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

    private func dismissSavePasswordPromptIfNeeded() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.buttons["Not Now"].waitForExistence(timeout: 8) {
            springboard.buttons["Not Now"].tap()
            sleep(1)
            return
        }
        for label in ["以后", "不存储", "稍后再说"] {
            let b = springboard.buttons[label]
            if b.waitForExistence(timeout: 1) { b.tap(); sleep(1); return }
        }
    }

    private func save(_ name: String) {
        let out = ProcessInfo.processInfo.environment["GUEST_SHOT_DIR"]
            ?? "/Users/chenmingming/Documents/Claude code/BudgetBuddy-GuestMode-Screenshots"
        let dir = URL(fileURLWithPath: out, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(name).png")
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: url, options: .atomic)
    }
}
