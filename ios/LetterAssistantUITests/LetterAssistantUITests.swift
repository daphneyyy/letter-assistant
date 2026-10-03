import XCTest

final class LetterAssistantUITests: XCTestCase {
    func testCalendarRequiresDateAndConfirmation() {
        let app = XCUIApplication()
        app.launchArguments += ["--calendar-review-test"]
        app.launch()
        app.buttons["Open test review"].tap()
        XCTAssertTrue(app.staticTexts["如果你希望更换计划"].exists)
        let open = app.buttons["确认并打开日历"]
        app.swipeUp(); app.swipeUp()
        XCTAssertFalse(open.isEnabled)
        app.swipeDown(); app.swipeDown()
        app.buttons["明天"].tap()
        let confirm = app.switches["我确认事项、适用条件、日期和时区"]
        app.swipeUp(); app.swipeUp()
        XCTAssertFalse(open.isEnabled)
        confirm.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        XCTAssertEqual(confirm.value as? String, "1")
        XCTAssertTrue(open.isEnabled)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Calendar-confirmation-Chinese"; attachment.lifetime = .keepAlways; add(attachment)
        open.tap()
        let cancel = app.buttons.matching(NSPredicate(format: "label == 'Cancel' OR label == '取消'")).firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 10))
        cancel.tap()
        let discard = app.buttons.matching(NSPredicate(format: "label == 'Discard Changes' OR label == '放弃更改' OR label == '丢弃更改'")).firstMatch
        if discard.waitForExistence(timeout: 3) { discard.tap() }
        XCTAssertTrue(app.staticTexts["已取消，信件内容未改变。"].waitForExistence(timeout: 5))
    }
    func testAppointmentRequiresExplicitDateTimeReviewAtLargeText() {
        let app = XCUIApplication()
        app.launchArguments += ["--calendar-review-test", "--appointment", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        app.buttons["Open test review"].tap()
        let open = app.buttons["确认并打开日历"]
        for _ in 0..<15 where !open.isHittable { app.swipeUp() }
        XCTAssertFalse(open.isEnabled)
        XCTAssertTrue(app.buttons["暂不添加"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Calendar-large-text"; attachment.lifetime = .keepAlways; add(attachment)
    }
    func testChineseCaptureScreenAtLargeText() {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        app.buttons["中文"].tap()
        XCTAssertTrue(app.staticTexts["一封信，清楚的下一步。"].exists)
        let take = app.buttons["拍摄信件"]
        for _ in 0..<5 where !take.isHittable { app.swipeUp() }
        XCTAssertTrue(take.isHittable)
        XCTAssertGreaterThanOrEqual(take.frame.height, 44)
        XCTAssertGreaterThanOrEqual(app.buttons["中文"].frame.height, 44)
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = "Chinese-large-text-capture"; attachment.lifetime = .keepAlways; add(attachment)
    }
}
