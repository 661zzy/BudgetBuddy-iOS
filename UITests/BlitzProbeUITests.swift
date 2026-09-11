import XCTest

// v1.6 财商快答: plays a whole daily round and a pack from the hub, and saves
// screenshots of every stage for a human look. `-bb.blitz.fast YES` shortens the
// lobby countdown and the read-the-question pause; the answer timer is untouched.
final class BlitzProbeUITests: XCTestCase {
    private var app: XCUIApplication!
    private var outDir: URL {
        let p = ProcessInfo.processInfo.environment["BB_SITE_SHOT_DIR"]
            ?? "/Users/chenmingming/Documents/Claude code/BudgetBuddy-1.6-快答/shots"
        let u = URL(fileURLWithPath: p, isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        let lang = ProcessInfo.processInfo.environment["BB_BLITZ_LANG"] ?? "zh"
        app.launchArguments += ["-bb.lang", lang, "-bb.blitz.fast", "YES",
                                "-bb.engage.prompted.v1", "YES", "-bb.review.prompted.v1", "YES",
                                "-bb.update.skippedBuild", "0"]
    }

    func testA_DailyRoundFromHome() throws {
        app.launch(); ensureInApp()
        let daily = app.buttons["blitz.daily"]
        if !daily.waitForExistence(timeout: 6) { app.swipeUp() }
        XCTAssertTrue(daily.waitForExistence(timeout: 6), "daily card missing on Home")
        shoot("0-home-card")
        daily.tap()
        playRound(count: 5, shotPrefix: "daily")
        finishRound(prefix: "daily")
        XCTAssertTrue(app.buttons["blitz.daily"].waitForExistence(timeout: 6), "did not return to Home")
    }

    func testB_PackFromHub() throws {
        app.launch(); ensureInApp()
        tapTab(["故事", "Stories"])
        let hub = app.buttons["blitz.hub"]
        for _ in 0..<4 where !hub.isHittable { app.swipeUp() }
        XCTAssertTrue(hub.waitForExistence(timeout: 6), "hub row missing under 更多")
        hub.tap()
        let pack = app.buttons["blitz.pack.scam"]
        XCTAssertTrue(pack.waitForExistence(timeout: 6), "pack grid missing")
        shoot("1-hub")
        pack.tap()
        playRound(count: 8, shotPrefix: "pack")
        finishRound(prefix: "pack")
    }

    // MARK: helpers

    private func playRound(count: Int, shotPrefix: String) {
        for i in 0..<count {
            let tile = app.buttons["blitz.tile.0"], slider = app.buttons["blitz.slider.submit"]
            let open = tile.waitForExistence(timeout: 12) || slider.waitForExistence(timeout: 2)
            XCTAssertTrue(open, "question \(i + 1) never opened")
            // Wait until the tiles are actually enabled (answering phase).
            let target = tile.exists ? tile : slider
            let deadline = Date().addingTimeInterval(8)
            while !target.isEnabled && Date() < deadline { usleep(100_000) }
            if i == 0 { shoot("\(shotPrefix)-2-question") }
            // Alternate taps so a round has both right and wrong answers.
            if tile.exists { app.buttons["blitz.tile.\(i % 2 == 0 ? 1 : 0)"].tap() } else { slider.tap() }
            let next = app.buttons["blitz.next"]
            XCTAssertTrue(next.waitForExistence(timeout: 6), "no reveal after question \(i + 1)")
            XCTAssertTrue(app.otherElements["blitz.why"].exists || app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", "为 什 么", "WHY")).firstMatch.exists,
                "reveal without an explanation")
            if i == 0 || i == 2 { shoot("\(shotPrefix)-3-reveal-q\(i + 1)") }
            next.tap()
        }
    }

    private func finishRound(prefix: String) {
        let podium = app.buttons["blitz.podium.continue"]
        XCTAssertTrue(podium.waitForExistence(timeout: 8), "podium missing")
        sleep(1)
        shoot("\(prefix)-4-podium")
        podium.tap()
        let done = app.buttons["blitz.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 6), "summary missing")
        shoot("\(prefix)-5-summary")
        done.tap()
    }

    private func shoot(_ name: String) {
        try? XCUIScreen.main.screenshot().pngRepresentation
            .write(to: outDir.appendingPathComponent("\(name).png"), options: .atomic)
    }

    private func ensureInApp() {
        if app.staticTexts["选择语言"].waitForExistence(timeout: 4) || app.staticTexts["Choose a language"].exists {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "中文")).firstMatch.tap(); sleep(1)
        }
        for l in ["跳过", "Skip"] where app.buttons[l].waitForExistence(timeout: 2) { app.buttons[l].tap(); break }
        _ = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", "今 日 故 事", "TODAY'S STORY"))
            .firstMatch.waitForExistence(timeout: 15)
    }

    private func tapTab(_ labels: [String]) {
        for l in labels {
            let t = app.tabBars.buttons[l].firstMatch
            if t.waitForExistence(timeout: 2) { t.tap(); sleep(1); return }
            let b = app.buttons[l].firstMatch
            if b.exists { b.tap(); sleep(1); return }
        }
    }
}
