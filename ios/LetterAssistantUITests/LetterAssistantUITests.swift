import XCTest

final class LetterAssistantUITests: XCTestCase {
    func testPageNavigationAndDeletion() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"]
        app.launch()
        let welcomeContinue = app.buttons["Continue"]
        if welcomeContinue.exists && welcomeContinue.isHittable { welcomeContinue.tap() }
        let sample = app.buttons["Use test photo"]
        XCTAssertTrue(sample.waitForExistence(timeout: 5)); sample.tap()
        let finish = app.buttons["analyzeDocument"]
        XCTAssertTrue(finish.waitForExistence(timeout: 5))
        for _ in 0..<2 {
            let next = app.buttons["Add next test photo"]
            for _ in 0..<6 where !next.isHittable { app.swipeUp() }
            next.tap()
            XCTAssertTrue(finish.waitForExistence(timeout: 5))
        }
        let selector = app.buttons["pageSelector"]
        for _ in 0..<6 where !selector.isHittable { app.swipeDown() }
        XCTAssertTrue(selector.label.contains("Page 3 of 3"))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Compact-page-navigation"; screenshot.lifetime = .keepAlways; add(screenshot)
        selector.tap(); app.buttons["Page 1"].tap()
        XCTAssertTrue(selector.label.contains("Page 1 of 3"))
        app.buttons["deletePage"].tap(); app.buttons["Keep page"].tap()
        XCTAssertTrue(selector.label.contains("Page 1 of 3"))
        for remaining in [2, 1] {
            app.buttons["deletePage"].tap(); app.buttons["Delete page"].tap()
            XCTAssertTrue(selector.label.contains("Page 1 of \(remaining)"))
        }
        app.buttons["deletePage"].tap(); app.buttons["Delete page"].tap()
        XCTAssertTrue(sample.waitForExistence(timeout: 3))
        XCTAssertFalse(selector.exists)
    }
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

    func testUndatedReminderDefaultsToTomorrowWithoutConfirmationSwitches() {
        let app = XCUIApplication()
        app.launchArguments += ["--calendar-review-test"]
        app.launch()
        app.buttons["Open test review"].tap()
        XCTAssertTrue(app.staticTexts["如果你希望更换计划"].exists)
        let open = app.buttons["添加到日历"]
        app.swipeUp(); app.swipeUp()
        XCTAssertTrue(open.isEnabled)
        app.swipeDown(); app.swipeDown()
        app.buttons["明天"].tap()
        app.swipeUp(); app.swipeUp()
        XCTAssertEqual(app.switches.count, 0)
        XCTAssertTrue(open.isEnabled)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Calendar-confirmation-Chinese"; attachment.lifetime = .keepAlways; add(attachment)
        open.tap()
        XCTAssertTrue(app.staticTexts["calendarConfirmation"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["savedEventTitle"].exists)
        XCTAssertTrue(app.staticTexts["savedEventDate"].exists)
        XCTAssertTrue(app.otherElements["savedEventAlert"].exists || app.staticTexts["savedEventAlert"].exists)
        let confirmation = XCTAttachment(screenshot: app.screenshot())
        confirmation.name = "Saved-calendar-confirmation"; confirmation.lifetime = .keepAlways; add(confirmation)
        let back = app.buttons["backToResult"]
        for _ in 0..<5 where !back.isHittable { app.swipeUp() }
        XCTAssertTrue(back.isHittable)
        back.tap()
        XCTAssertTrue(app.buttons["Open test review"].waitForExistence(timeout: 3))
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
        XCTAssertTrue(app.navigationBars["核对日历事项"].exists)
        let picker = app.datePickers["customAlertDate"]
        for _ in 0..<5 where !picker.exists { app.swipeUp() }
        XCTAssertTrue(picker.exists)
        XCTAssertTrue(app.datePickers["customAlertTime"].exists)
        let custom = XCTAttachment(screenshot: app.screenshot())
        custom.name = "Aligned-custom-alert-controls"; custom.lifetime = .keepAlways; add(custom)
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
        app.launchArguments += ["--calendar-review-test", "--appointment", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launch()
        app.buttons["Open test review"].tap()
        let choose = app.datePickers["eventDate"]
        for _ in 0..<8 where !choose.isHittable { app.swipeUp() }
        choose.buttons.firstMatch.tap()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        if Calendar.current.component(.month, from: tomorrow) != Calendar.current.component(.month, from: Date()) {
            app.buttons["DatePicker.NextMonth"].tap()
        }
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
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
        XCTAssertFalse(app.staticTexts["calendarConfirmation"].exists)
    }

    func testChineseCaptureScreenAtLargeText() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN",
                                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let welcomeContinue = app.buttons["继续"]
        if welcomeContinue.exists && welcomeContinue.isHittable { welcomeContinue.tap() }
        XCTAssertTrue(app.buttons["使用测试照片"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["languageMenu"].exists)
        XCTAssertEqual(app.buttons["languageSettings"].label, "语言设置")
        XCTAssertFalse(app.staticTexts["一封信，清楚的下一步。"].exists)
        XCTAssertFalse(app.staticTexts["One letter. Clear next steps."].exists)
        XCTAssertTrue(app.buttons["使用测试照片"].exists)
        let choosePhoto = app.buttons["uploadFile"]
        XCTAssertTrue(choosePhoto.exists)
        XCTAssertTrue(choosePhoto.label.contains("上传文档（PDF）"))
        XCTAssertTrue(app.buttons["uploadExistingPhoto"].exists)
        let take = app.buttons["takePhoto"]
        for _ in 0..<5 where !take.isHittable { app.swipeUp() }
        XCTAssertTrue(take.isHittable)
        XCTAssertGreaterThanOrEqual(take.frame.height, 44)
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = "Chinese-large-text-capture"; attachment.lifetime = .keepAlways; add(attachment)
        for _ in 0..<5 where !choosePhoto.isHittable { app.swipeUp() }
        choosePhoto.tap()
        let cancel = app.buttons["取消"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        cancel.tap()
        XCTAssertTrue(choosePhoto.waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["开始分析"].exists)
    }
    func testEnglishPhoneLanguageAppliesToWelcomeAndCapture() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let welcomeContinue = app.buttons["Continue"]
        if welcomeContinue.exists && welcomeContinue.isHittable { welcomeContinue.tap() }
        XCTAssertTrue(app.buttons["Use test photo"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["languageMenu"].exists)
        XCTAssertFalse(app.buttons["使用测试照片"].exists)
        XCTAssertEqual(app.buttons["languageSettings"].label, "Language settings")
    }
    func testLanguageButtonOpensSystemSettings() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let languageSettings = app.buttons["languageSettings"]
        XCTAssertTrue(languageSettings.waitForExistence(timeout: 5))
        languageSettings.tap()
        XCTAssertTrue(app.alerts["Open language settings?"].waitForExistence(timeout: 3))
        app.alerts.buttons["Open Settings"].tap()
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 5))
    }
    func testLanguageSettingsWarningKeepsUnsavedLetterWhenCanceled() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let sample = app.buttons["Use test photo"]
        XCTAssertTrue(sample.waitForExistence(timeout: 5))
        sample.tap()
        XCTAssertTrue(app.buttons["analyzeDocument"].waitForExistence(timeout: 5))
        app.buttons["languageSettings"].tap()
        XCTAssertTrue(app.alerts["Open language settings?"].waitForExistence(timeout: 3))
        app.alerts.buttons["Keep reading"].tap()
        XCTAssertTrue(app.buttons["analyzeDocument"].exists)
    }
}
