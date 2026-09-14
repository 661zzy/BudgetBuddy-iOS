import XCTest

// v1.6.1 自定义记账分类 — end to end on the review account (credentials from env).
// Split in two so the cloud copy can be checked from outside between them:
//   testA  create a category, log an entry, sign out and back in → still there
//   testB  rename (history follows), reject a built-in name, then delete
//          everything this suite created so the review account is left clean.
final class CustomCategoryUITests: XCTestCase {
    private var app: XCUIApplication!
    private let account = ProcessInfo.processInfo.environment["BB_REVIEW_ACCOUNT"] ?? "review@budgetbuddy.cn"
    private let password = ProcessInfo.processInfo.environment["BB_REVIEW_PASSWORD"] ?? ""
    private let catName = "测试水电"
    private let renamed = "测试水电费"
    private var outDir: URL {
        let p = ProcessInfo.processInfo.environment["BB_SITE_SHOT_DIR"]
            ?? "/Users/chenmingming/Documents/Claude code/BudgetBuddy-1.6.1-自定义分类/shots"
        let u = URL(fileURLWithPath: p, isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipIf(password.isEmpty, "Set BB_REVIEW_PASSWORD to run account-based tests")
        app = XCUIApplication()
        app.launchArguments += ["-bb.lang", "zh", "-bb.engage.prompted.v1", "YES", "-bb.review.prompted.v1", "YES"]
        app.launch()
        ensureInApp()
        signInIfGuest()
    }

    /// Other suites on this simulator assume a guest. Always sign out on the way
    /// out, even after a failure (best effort, no assertions).
    override func tearDownWithError() throws {
        guard let app, app.state == .runningForeground else { return }
        for label in ["取消"] where app.navigationBars.buttons[label].exists { app.navigationBars.buttons[label].tap() }
        let tab = app.tabBars.buttons["我的"].firstMatch
        guard tab.waitForExistence(timeout: 3) else { return }
        tab.tap()
        let out = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "退出登录")).firstMatch
        for _ in 0..<6 where !(out.exists && out.isHittable) { app.swipeUp() }
        if out.exists && out.isHittable { out.tap(); _ = waitForText("未登录", timeout: 8) }
    }

    func testA_CreateLogAndSurviveSignOut() throws {
        openAddSheet()
        let chip = app.buttons["cat.chip.\(catName)"]
        if chip.waitForExistence(timeout: 2) {
            // Left over from an interrupted run — reuse it rather than fail on the duplicate.
            reveal(chip); chip.tap()
        } else {
            app.buttons["cat.add.header"].tap()
            let field = app.textFields["cat.editor.name"]
            XCTAssertTrue(field.waitForExistence(timeout: 5), "editor did not open")
            field.tap(); field.typeText(catName)
            dismissKeyboardTipIfShown()
            app.buttons["cat.editor.icon.bolt.fill"].tap()
            shoot("1-editor")
            app.buttons["cat.editor.save"].tap()
            XCTAssertTrue(waitGone(field, 6), "editor did not close after saving")
            XCTAssertTrue(chip.waitForExistence(timeout: 5), "new chip missing after save")
        }
        shoot("2-chip-selected")
        app.buttons["1"].firstMatch.tap()
        tapButton(containing: "记一笔")
        if app.buttons["跳过"].waitForExistence(timeout: 5) { app.buttons["跳过"].tap() }
        XCTAssertTrue(waitForText(catName, timeout: 8), "entry with the custom category not in the list")
        shoot("3-list-row")

        // Sign out wipes local state; signing back in must bring the category back from the account.
        signOut()
        app.terminate(); app.launch()      // signing out rebuilds the UI; start clean as a guest
        ensureInApp()
        signInIfGuest()
        openAddSheet()
        XCTAssertTrue(app.buttons["cat.chip.\(catName)"].waitForExistence(timeout: 8),
                      "custom category did not come back after signing in again")
        shoot("4-after-relogin")
        tapButton(containing: "取消")
    }

    func testB_RenameValidateAndCleanUp() throws {
        openAddSheet()
        let chip = app.buttons["cat.chip.\(catName)"]
        let renamedChip = app.buttons["cat.chip.\(renamed)"]
        let field = app.textFields["cat.editor.name"]
        XCTAssertTrue(chip.waitForExistence(timeout: 8) || renamedChip.exists, "testA's category missing — run testA first")

        if chip.exists {
            // Rename through the long-press menu.
            reveal(chip)
            chip.press(forDuration: 1.2)
            let renameItem = app.buttons["重命名"]
            XCTAssertTrue(renameItem.waitForExistence(timeout: 4), "context menu missing")
            shoot("5-context-menu")
            renameItem.tap()
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            field.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
            field.typeText("费")
            dismissKeyboardTipIfShown()
            app.buttons["cat.editor.save"].tap()
            XCTAssertTrue(waitGone(field, 6), "editor did not close after rename")
            XCTAssertTrue(renamedChip.waitForExistence(timeout: 5), "rename not applied")
            XCTAssertFalse(chip.exists)
        }

        // A built-in name is refused with a message.
        let add = app.buttons["cat.add.header"]
        XCTAssertTrue(add.waitForExistence(timeout: 4))
        add.tap()
        XCTAssertTrue(field.waitForExistence(timeout: 5), "editor did not open")
        field.tap(); field.typeText("餐饮")
        dismissKeyboardTipIfShown()
        app.buttons["cat.editor.save"].tap()
        XCTAssertTrue(app.staticTexts["cat.editor.error"].waitForExistence(timeout: 4), "built-in name was not refused")
        shoot("6-builtin-refused")
        app.navigationBars["新建分类"].buttons["取消"].tap()
        XCTAssertTrue(waitGone(field, 6), "editor did not close")

        // Delete the category.
        XCTAssertTrue(renamedChip.waitForExistence(timeout: 5))
        reveal(renamedChip)
        renamedChip.press(forDuration: 1.2)
        let delItem = app.buttons["删除"].firstMatch
        XCTAssertTrue(delItem.waitForExistence(timeout: 4), "context menu missing")
        delItem.tap()
        let confirm = app.buttons.matching(NSPredicate(format: "label == %@", "删除")).element(boundBy: 0)
        XCTAssertTrue(confirm.waitForExistence(timeout: 4), "delete confirmation missing")
        shoot("7-delete-confirm")
        confirm.tap()
        XCTAssertTrue(waitGone(renamedChip, 6), "chip still there after delete")
        app.navigationBars["记一笔"].buttons["取消"].tap()

        // History followed the rename; delete every entry this suite logged.
        let row = app.cells.containing(.staticText, identifier: renamed).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 6), "renamed entry not in the list (history should follow a rename)")
        shoot("8-row-renamed")
        for _ in 0..<6 where row.waitForExistence(timeout: 2) {
            row.swipeLeft()
            let del = app.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Delete", "删除")).firstMatch
            XCTAssertTrue(del.waitForExistence(timeout: 4), "swipe delete button missing")
            del.tap()
            sleep(2)
        }
        XCTAssertFalse(app.cells.containing(.staticText, identifier: renamed).firstMatch.exists, "test entries left behind")
        sleep(3)   // let the save reach the server before the process ends
    }

    // MARK: helpers

    /// First keyboard use on a fresh simulator shows a slide-to-type tip over the sheet.
    private func dismissKeyboardTipIfShown() {
        let cont = app.buttons["Continue"]
        if cont.waitForExistence(timeout: 1) { cont.tap() }
    }

    /// Chips sit in a horizontal scroll row; bring one on screen before pressing it.
    private func reveal(_ chip: XCUIElement) {
        let row = app.scrollViews.containing(.button, identifier: "cat.chip.food").firstMatch
        for _ in 0..<6 where !chip.isHittable { row.swipeRight() }
        for _ in 0..<6 where !chip.isHittable { row.swipeLeft() }
    }

    private func openAddSheet() {
        tapTab("记账")
        let plus = app.navigationBars.buttons.matching(
            NSPredicate(format: "identifier CONTAINS %@ OR label CONTAINS %@ OR label CONTAINS %@", "plus", "添加", "Add")).firstMatch
        XCTAssertTrue(plus.waitForExistence(timeout: 8), "+ missing (not signed in?)")
        plus.tap()
        XCTAssertTrue(app.buttons["cat.add.header"].waitForExistence(timeout: 6), "add sheet did not open")
    }

    private func signOut() {
        tapTab("我的")
        tapButton(containing: "退出登录")
        XCTAssertTrue(waitForText("未登录", timeout: 10), "sign-out did not finish")
    }

    private func signInIfGuest() {
        tapTab("我的")
        guard waitForText("未登录", timeout: 4) else { return }
        tapButton(containing: "登录 / 注册")
        XCTAssertTrue(waitForText("欢迎回来", timeout: 6), "login sheet missing")
        let idField = app.textFields["手机号或邮箱"].exists ? app.textFields["手机号或邮箱"] : app.textFields.element(boundBy: 0)
        XCTAssertTrue(idField.waitForExistence(timeout: 5))
        idField.tap(); idField.typeText(account)
        let pw = app.secureTextFields.element(boundBy: 0)
        pw.tap(); pw.typeText(password)
        // Two buttons read 登录: the mode switch at the top and the submit button
        // below the fields. The submit one is the lower of the two.
        let submit = app.buttons.matching(NSPredicate(format: "label == %@", "登录")).allElementsBoundByIndex
            .max(by: { $0.frame.minY < $1.frame.minY })
        XCTAssertNotNil(submit, "submit button missing")
        submit?.tap()
        // Signing in rebuilds the tab view (lands on Home), so wait for the sheet
        // to go away rather than for text on the profile page.
        XCTAssertTrue(waitGone(app.staticTexts["欢迎回来"], 25), "login sheet did not close")
        dismissSavePasswordPromptIfNeeded()
        tapTab("我的")
        XCTAssertFalse(waitForText("未登录", timeout: 3), "still a guest after signing in")
    }

    private func ensureInApp() {
        if app.staticTexts["选择语言"].waitForExistence(timeout: 3) {
            app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "中文")).firstMatch.tap(); sleep(1)
        }
        if app.buttons["跳过"].waitForExistence(timeout: 3) { app.buttons["跳过"].tap() }
        XCTAssertTrue(waitForText("今 日 故 事", timeout: 15), "main UI not reached")
    }

    private func tapTab(_ label: String) {
        let t = app.tabBars.buttons[label].firstMatch
        if t.waitForExistence(timeout: 3), t.isHittable { t.tap(); sleep(1); return }
        let b = app.buttons[label].firstMatch
        if b.waitForExistence(timeout: 2) { b.tap(); sleep(1) }
    }

    private func waitForText(_ text: String, timeout: TimeInterval) -> Bool {
        let p = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.matching(p).firstMatch.waitForExistence(timeout: timeout)
            || app.buttons.matching(p).firstMatch.waitForExistence(timeout: 0.3)
    }

    private func waitGone(_ e: XCUIElement, _ t: TimeInterval) -> Bool {
        let end = Date().addingTimeInterval(t)
        while Date() < end { if !e.exists { return true }; usleep(200_000) }
        return !e.exists
    }

    private func tapButton(containing text: String) {
        let target = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        for _ in 0..<8 {
            if target.exists && target.isHittable { target.tap(); return }
            app.swipeUp(); usleep(300_000)
        }
        XCTFail("button containing '\(text)' not reachable")
    }

    private func dismissSavePasswordPromptIfNeeded() {
        let sb = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Not Now", "以后", "不存储", "稍后再说"] where sb.buttons[label].waitForExistence(timeout: label == "Not Now" ? 6 : 1) {
            sb.buttons[label].tap(); sleep(1); return
        }
    }

    private func shoot(_ n: String) {
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: outDir.appendingPathComponent("\(n).png"), options: .atomic)
    }
}
