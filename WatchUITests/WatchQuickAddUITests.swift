import XCTest

// Watch quick-add smoke. The watchOS simulator delivers synthetic taps with a
// large coordinate offset (element frames vs actual hit points drift ~60pt),
// which makes keypad-digit driving hopeless in CI — that part is covered by a
// rendering assertion + screenshot + real-device checklist. What this test
// proves end-to-end is the part that matters: amount → category → save →
// WatchConnectivity queue → (runner then checks the entry landed on the phone).
final class WatchQuickAddUITests: XCTestCase {

    func testSaveAndSyncFlow() throws {
        let app = XCUIApplication()
        // v1.6.1: stands in for the phone's custom-category push (application context
        // can't be delivered in the simulator). Kept in this one test on purpose: the
        // watch simulator fails to start the app a second time within the same run,
        // so every check has to share a single launch.
        app.launchArguments = ["-bb.uitest.prefill", "15",
                               "-bb.uitest.customCats", #"[{"name":"水电","icon":"bolt.fill"},{"name":"房租","icon":"house.fill"}]"#]
        app.launch()

        // keypad + prefilled amount render
        let display = app.staticTexts["watch.amount"].firstMatch
        XCTAssertTrue(display.waitForExistence(timeout: 15), "金额显示未渲染")
        XCTAssertEqual(display.label, "¥15", "预填金额未生效")
        XCTAssertTrue(app.buttons["1"].exists, "键盘未渲染")
        sleep(1)
        save(app, "w1-keypad")

        // 选分类 (NavigationLink taps work; keypad digits are the only casualty)
        let pick = app.buttons["选分类"].firstMatch
        XCTAssertTrue(pick.isEnabled, "选分类未启用")
        pick.tap()
        if !app.buttons["餐饮"].waitForExistence(timeout: 5) {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.93)).tap()
            XCTAssertTrue(app.buttons["餐饮"].waitForExistence(timeout: 5), "分类列表未出现")
        }
        save(app, "w2-category")

        // Custom categories pushed from the phone are listed after the built-ins.
        let water = app.buttons["watch.cat.水电"].firstMatch
        for _ in 0..<6 where !water.exists { app.swipeUp() }
        XCTAssertTrue(water.waitForExistence(timeout: 3), "自定义分类「水电」没有出现在手表分类列表里")
        XCTAssertTrue(app.buttons["watch.cat.房租"].exists, "自定义分类「房租」缺失")
        save(app, "w4-custom-categories")
        for _ in 0..<6 where !app.buttons["餐饮"].firstMatch.isHittable { app.swipeDown() }

        // 餐饮 → queue + pop back to the confirmation
        app.buttons["餐饮"].firstMatch.tap()
        if !app.staticTexts["已记下"].waitForExistence(timeout: 5) {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)).tap()
            _ = app.staticTexts["已记下"].waitForExistence(timeout: 5)
        }
        XCTAssertTrue(app.staticTexts["已记下"].exists, "保存确认页未出现")
        save(app, "w3-saved")
        sleep(4)   // let WCSession hand the transfer to the paired phone
    }

    private func save(_ app: XCUIApplication, _ name: String) {
        let dir = URL(fileURLWithPath: "/Users/chenmingming/Documents/Claude code/BudgetBuddy-Watch-Screenshots", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(
            to: dir.appendingPathComponent("\(name).png"), options: .atomic)
    }
}
