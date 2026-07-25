import XCTest
import UIKit

// v1.1 (build 17) smoke — runs on BOTH iPhone and iPad destinations:
// every tab renders (iPad layouts width-capped, tab bar sits on TOP on iPadOS 18+),
// and the new 去 App Store 评分 row exists in 我的. testA expects a fresh install.
// Screenshots land in BudgetBuddy-V11-Screenshots/<iphone|ipad>/ — the iPad Pro 13"
// portrait shots (2064×2752) are directly usable in App Store Connect.
final class V11SmokeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // Fresh install: language → onboarding → guest home, then walk every tab.
    func testA_TabsRenderAndShots() throws {
        if app.staticTexts["选择语言"].waitForExistence(timeout: 6) {
            save("00-language")
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "中文")).firstMatch.tap()
            sleep(1)
        }
        if app.buttons["跳过"].waitForExistence(timeout: 5) {
            save("01-onboarding")
            app.buttons["跳过"].tap()
        }
        XCTAssertTrue(mainAppVisible(timeout: 15), "Home did not render")
        sleep(2)
        save("02-home")

        tapTab("故事")
        XCTAssertTrue(waitForText("互动故事", timeout: 8), "Story hub did not render")
        sleep(1)
        save("03-story-hub")
        // Open a story intro (a width-capped detail page) and come back.
        let node = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "story-node-")).firstMatch
        if node.waitForExistence(timeout: 4), node.isHittable {
            node.tap()
            XCTAssertTrue(waitForText("开始游戏", timeout: 8), "Story intro did not open")
            sleep(1)
            save("04-story-intro")
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)
        }

        tapTab("AI搭子")
        XCTAssertTrue(waitForText("AI搭子", timeout: 8), "AI tab did not render")
        sleep(1)
        save("05-ai")

        tapTab("记账")
        _ = waitForText("欢迎回来", timeout: 8)   // guest → auth sheet auto-presents
        sleep(1)
        save("06-tracker-auth-sheet")
        tapButtonIfExists(containing: "暂不登录")
        sleep(1)

        tapTab("我的")
        XCTAssertTrue(waitForText("未登录", timeout: 8), "Profile did not render")
        sleep(1)
        save("07-profile")
    }

    // The new review entry is present in 我的. Existence only — the real jump is
    // exercised separately in testC (it leaves the app, so it must run last).
    func testB_RateAppRowPresent() throws {
        ensureInApp()
        tapTab("我的")
        let row = rateRow()
        XCTAssertTrue(row != nil, "去 App Store 评分 row missing from 我的")
        save("08-profile-rate-row")
    }

    // Tap the review entry for real: the app must background and hand off to the
    // system. Real device: the App Store opens the write-review sheet natively
    // (apps.apple.com is its universal link; Safari never appears). Simulator:
    // there is NO native store app, so Safari opens and — for ANY store link,
    // even one fired via `simctl openurl` with no app involved — shows an
    // "address is invalid" alert when the page bounces to the native store.
    // That alert is therefore recorded as evidence, not judged: the assertions
    // here are "left the app" + "Safari or App Store came to the foreground".
    // The definitive review-sheet check is a one-tap manual test on a real phone.
    func testC_RatingJumpLeavesApp() throws {
        ensureInApp()
        tapTab("我的")
        guard let row = rateRow() else { XCTFail("评分入口不存在"); return }
        row.tap()

        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 10), "点击评分后未离开 App")
        let appStore = XCUIApplication(bundleIdentifier: "com.apple.AppStore")
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        let storeFront = appStore.wait(for: .runningForeground, timeout: 6)
        let safariFront = storeFront ? false : safari.wait(for: .runningForeground, timeout: 6)
        XCTAssertTrue(storeFront || safariFront, "既没打开 App Store 也没打开 Safari")
        sleep(3)
        // The simulator's "address is invalid" alert (any store link bounces to
        // the absent native store) is hosted by a process XCUITest can't query
        // reliably — so no programmatic judgment: the screenshot is the evidence,
        // and the alert is EXPECTED on simulator / must not appear on real device.
        save(storeFront ? "12-rating-jump-appstore" : "12-rating-jump-safari")
    }

    /// Scroll 我的 until the rate row is present and hittable; nil if never found.
    private func rateRow() -> XCUIElement? {
        let row = app.buttons["profile.rate.app"].firstMatch
        var swipes = 0
        while !(row.exists && row.isHittable) && swipes < 6 {
            if row.exists && !row.isHittable { usleep(400_000) }
            app.swipeUp()
            swipes += 1
        }
        _ = row.waitForExistence(timeout: 1)
        return (row.exists && row.isHittable) ? row : nil
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

    // Works on iPhone (bottom tab bar) AND iPadOS 18+ (top tab bar):
    // prefer the real tab-bar element, fall back to any exact-label button.
    private func tapTab(_ label: String) {
        let tabButton = app.tabBars.buttons[label].firstMatch
        if tabButton.waitForExistence(timeout: 2), tabButton.isHittable {
            tabButton.tap(); sleep(1); return
        }
        let anyButton = app.buttons[label].firstMatch
        if anyButton.waitForExistence(timeout: 2), anyButton.isHittable {
            anyButton.tap(); sleep(1); return
        }
        // Last resort: bottom-bar coordinates (pre-18 iPhone layout).
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

    private func save(_ name: String) {
        let idiom = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        let out = ProcessInfo.processInfo.environment["V11_SHOT_DIR"]
            ?? "/Users/chenmingming/Documents/Claude code/BudgetBuddy-V11-Screenshots"
        let dir = URL(fileURLWithPath: out, isDirectory: true).appendingPathComponent(idiom, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(name).png")
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: url, options: .atomic)
    }
}
