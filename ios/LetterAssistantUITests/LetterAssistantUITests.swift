import XCTest

final class LetterAssistantUITests: XCTestCase {
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
