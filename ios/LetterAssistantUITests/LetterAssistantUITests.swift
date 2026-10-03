import XCTest

final class LetterAssistantUITests: XCTestCase {
    func testDeadlineDateAndTimeZoneAreEditable() {
        let app = XCUIApplication()
        app.launchArguments += ["--calendar-review-test", "--known-deadline"]
        app.launch(); app.buttons["Open test review"].tap()
        let zone = app.buttons["eventTimeZone"]
        XCTAssertTrue(zone.waitForExistence(timeout: 3))
        XCTAssertTrue(zone.label.contains(TimeZone.current.identifier) || (zone.value as? String) == TimeZone.current.identifier)
        zone.tap()
        let alternate = app.buttons["America/Lima"]
        XCTAssertTrue(alternate.isHittable); alternate.tap()
        XCTAssertTrue(app.navigationBars["核对日历事项"].exists)
        XCTAssertTrue(zone.label.contains("America/Lima") || (zone.value as? String) == "America/Lima")
        let date = app.datePickers["eventDate"]
        XCTAssertTrue(date.exists); XCTAssertTrue(date.isEnabled)
        date.tap()
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Editable-deadline-date"; screenshot.lifetime = .keepAlways; add(screenshot)
    }

    func testCalendarRequiresDateWithoutConfirmationSwitches() {
        let app = XCUIApplication()
        app.launchArguments += ["--calendar-review-test"]
        app.launch()
        app.buttons["Open test review"].tap()
        XCTAssertTrue(app.staticTexts["如果你希望更换计划"].exists)
        let open = app.buttons["添加到日历"]
        app.swipeUp(); app.swipeUp()
        XCTAssertFalse(open.isEnabled)
        app.swipeDown(); app.swipeDown()
        app.buttons["明天"].tap()
        app.swipeUp(); app.swipeUp()
        XCTAssertEqual(app.switches.count, 0)
        XCTAssertTrue(open.isEnabled)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Calendar-confirmation-Chinese"; attachment.lifetime = .keepAlways; add(attachment)
        open.tap()
        XCTAssertTrue(app.staticTexts["已保存到日历。后续修改和提醒设置请在日历中管理。"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["New Event"].exists)
    }
    func testAppointmentRequiresExplicitDateTimeReviewAtLargeText() {
        let app = XCUIApplication()
        app.launchArguments += ["--calendar-review-test", "--appointment", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        app.buttons["Open test review"].tap()
        let open = app.buttons["添加到日历"]
        for _ in 0..<15 where !open.isHittable { app.swipeUp() }
        XCTAssertFalse(open.isEnabled)
        let cancel = app.buttons["暂不添加"]
        for _ in 0..<5 where !cancel.isHittable { app.swipeUp() }
        XCTAssertTrue(cancel.isHittable)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Calendar-large-text"; attachment.lifetime = .keepAlways; add(attachment)
    }
    func testCustomAlertShowsDateAndTimePicker() {
        let app = XCUIApplication()
        app.launchArguments += ["--calendar-review-test"]
        app.launch()
        app.buttons["Open test review"].tap()
        let notify = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "提醒我")).firstMatch
        for _ in 0..<8 where !notify.isHittable { app.swipeUp() }
        XCTAssertTrue(notify.isHittable)
        notify.tap()
        app.buttons["自定义日期和时间"].tap()
        let picker = app.datePickers["customAlertDate"]
        for _ in 0..<5 where !picker.exists { app.swipeUp() }
        XCTAssertTrue(picker.exists)
    }

    func testDurationEstimateAndCustomEntry() {
        let app = XCUIApplication()
        app.launchArguments += ["--calendar-review-test", "--appointment", "--duration-estimate"]
        app.launch()
        app.buttons["Open test review"].tap()
        let duration = app.buttons["durationPicker"]
        for _ in 0..<10 where !duration.isHittable { app.swipeUp() }
        XCTAssertTrue(duration.isHittable)
        XCTAssertTrue((duration.value as? String)?.contains("50") == true)
        duration.tap()
        app.buttons["自定义时长"].tap()
        let field = app.textFields["customDuration"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText(XCUIKeyboardKey.delete.rawValue + XCUIKeyboardKey.delete.rawValue + "0")
        XCTAssertTrue(app.staticTexts["invalidDuration"].exists)
        field.typeText(XCUIKeyboardKey.delete.rawValue + "75")
        app.buttons["完成"].tap()
        XCTAssertFalse(app.staticTexts["invalidDuration"].exists)
        XCTAssertTrue(app.otherElements["durationEnd"].exists || app.staticTexts["结束时间"].exists)
        let open = app.buttons["添加到日历"]
        for _ in 0..<10 where !open.isHittable { app.swipeUp() }
        XCTAssertFalse(open.isEnabled)
    }

    func testKnownAppointmentCanContinueWithoutConfirmationSwitches() {
        let app = XCUIApplication()
        app.launchArguments += ["--calendar-review-test", "--appointment", "--known-appointment"]
        app.launch()
        app.buttons["Open test review"].tap()
        let open = app.buttons["添加到日历"]
        for _ in 0..<12 where !open.isHittable { app.swipeUp() }
        XCTAssertTrue(open.isEnabled)
        XCTAssertEqual(app.switches.count, 0)
    }

    func testMissingAppointmentTimeCanBeSelectedWithoutCheckbox() {
        let app = XCUIApplication()
        app.launchArguments += ["--calendar-review-test", "--appointment"]
        app.launch()
        app.buttons["Open test review"].tap()
        let choose = app.datePickers["eventDate"]
        for _ in 0..<8 where !choose.isHittable { app.swipeUp() }
        choose.buttons.firstMatch.tap()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        if Calendar.current.component(.month, from: tomorrow) != Calendar.current.component(.month, from: Date()) {
            app.buttons["DatePicker.NextMonth"].tap()
        }
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE, MMMM d"
        app.buttons[formatter.string(from: tomorrow)].tap()
        XCTAssertFalse(app.navigationBars["选择日期"].exists)
        app.navigationBars["核对日历事项"].tap()
        let open = app.buttons["添加到日历"]
        for _ in 0..<12 where !open.isHittable { app.swipeUp() }
        XCTAssertTrue(open.isEnabled)
        XCTAssertEqual(app.switches.count, 0)
    }

    func testDirectSaveDeniedKeepsReviewAndOffersSettings() {
        let app = XCUIApplication()
        app.launchArguments += ["--calendar-review-test", "--appointment", "--known-appointment", "--save-denied"]
        app.launch(); app.buttons["Open test review"].tap()
        let add = app.buttons["添加到日历"]
        for _ in 0..<12 where !add.isHittable { app.swipeUp() }
        add.tap()
        XCTAssertTrue(app.staticTexts["calendarSaveError"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["打开设置"].exists)
        XCTAssertFalse(app.staticTexts["已保存到日历。后续修改和提醒设置请在日历中管理。"].exists)
    }

    func testChineseCaptureScreenAtLargeText() {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["中文"].waitForExistence(timeout: 5))
        app.buttons["中文"].tap()
        XCTAssertFalse(app.staticTexts["一封信，清楚的下一步。"].exists)
        XCTAssertFalse(app.staticTexts["One letter. Clear next steps."].exists)
        XCTAssertTrue(app.buttons["使用测试照片"].exists)
        let take = app.buttons["拍摄信件"]
        for _ in 0..<5 where !take.isHittable { app.swipeUp() }
        XCTAssertTrue(take.isHittable)
        XCTAssertGreaterThanOrEqual(take.frame.height, 44)
        XCTAssertGreaterThanOrEqual(app.buttons["中文"].frame.height, 44)
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = "Chinese-large-text-capture"; attachment.lifetime = .keepAlways; add(attachment)
    }
}
