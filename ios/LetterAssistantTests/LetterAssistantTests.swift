import XCTest
import UIKit
import CoreImage
import EventKit
@testable import LetterAssistant

final class LetterAssistantTests: XCTestCase {
    func testUndatedReminderDefaultsToTomorrowAcrossMidnightAndDST() {
        for date in ["2026-03-07", "2026-10-31", "2026-12-31"] {
            let today = CalendarDatePolicy.parseDay(date, calendar: calendar)!
            let now = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: today)!
            let reminder = CalendarProposal.testExample(.reminder, language: .en, now: now, calendar: calendar)
            XCTAssertNil(reminder.date)
            XCTAssertEqual(reminder.initialDate(now: now, calendar: calendar), CalendarDatePolicy.addingDays(1, to: today, calendar: calendar))
        }
    }
    func testDatedEventDefaultsAlertToPreviousDay() {
        let day = CalendarDatePolicy.parseDay("2026-11-02", calendar: calendar)!
        let appointment = CalendarDatePolicy.appointmentDate(day: day, time: "10:30", calendar: calendar)!
        let alert = CalendarAlertChoice.defaultChoice(for: .appointment).fireDate(start: appointment, calendar: calendar)!
        XCTAssertTrue(calendar.isDate(alert, inSameDayAs: CalendarDatePolicy.addingDays(-1, to: day, calendar: calendar)))
        XCTAssertEqual(calendar.component(.hour, from: alert), 10)
        let deadlineAlert = CalendarAlertChoice.defaultChoice(for: .deadline).fireDate(start: day, calendar: calendar)!
        XCTAssertTrue(calendar.isDate(deadlineAlert, inSameDayAs: alert))
        XCTAssertEqual(calendar.component(.hour, from: deadlineAlert), 9)
    }
    func testPhoneLanguageSelectionUsesPreferenceOrderAndEnglishFallback() {
        XCTAssertEqual(AppLanguage.preferred(for: ["zh-Hans-CN", "en-US"]), .zh)
        XCTAssertEqual(AppLanguage.preferred(for: ["zh-Hant-TW"]), .zh)
        XCTAssertEqual(AppLanguage.preferred(for: ["en-GB", "zh-Hans"]), .en)
        XCTAssertEqual(AppLanguage.preferred(for: ["fr-FR", "zh-Hans", "en"]), .zh)
        XCTAssertEqual(AppLanguage.preferred(for: ["fr-FR"]), .en)
        XCTAssertEqual(AppLanguage.preferred(for: []), .en)
    }
    @MainActor func testCaptureStartsInPhoneLanguage() {
        XCTAssertEqual(CaptureModel().language, AppLanguage.system)
    }
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return result
    }
    func testSystemCalendarEventPreservesAllDayAndTimedAppointment() {
        let start = CalendarDatePolicy.parseDay("2026-03-08", calendar: calendar)!
        let store = EKEventStore()
        let allDay = CalendarEventRequest(title: "Test deadline", notes: "Fictional", start: start,
            end: CalendarDatePolicy.end(start: start, allDay: true, minutes: 30, calendar: calendar),
            allDay: true, timeZone: calendar.timeZone).makeEvent(in: store)
        XCTAssertTrue(allDay.isAllDay)
        XCTAssertNil(allDay.timeZone)
        XCTAssertEqual(calendar.dateComponents([.year, .month, .day], from: allDay.startDate),
                       calendar.dateComponents([.year, .month, .day], from: start))
        let appointment = CalendarEventRequest(title: "Test appointment", notes: "Fictional", start: start,
            end: start.addingTimeInterval(1800), allDay: false, timeZone: calendar.timeZone).makeEvent(in: store)
        XCTAssertFalse(appointment.isAllDay)
        XCTAssertEqual(appointment.timeZone, calendar.timeZone)
        XCTAssertEqual(appointment.endDate.timeIntervalSince(appointment.startDate), 1800)
    }
    func testCalendarAlertsAreAttachedAndCanBeDisabled() {
        let start = CalendarDatePolicy.parseDay("2026-10-05", calendar: calendar)!
        let store = EKEventStore()
        for choice in [CalendarAlertChoice.none, .sameDayMorning, .previousDayMorning] {
            let event = CalendarEventRequest(title: "Test", notes: "", start: start,
                end: CalendarDatePolicy.end(start: start, allDay: true, minutes: 30, calendar: calendar),
                allDay: true, timeZone: calendar.timeZone, alert: choice).makeEvent(in: store)
            XCTAssertTrue(event.isAllDay)
            XCTAssertNil(event.timeZone)
            if choice == .none {
                XCTAssertTrue(event.alarms?.isEmpty ?? true)
            } else {
                XCTAssertEqual(event.alarms?.count, 1)
                let fire = start.addingTimeInterval(event.alarms!.first!.relativeOffset)
                XCTAssertEqual(calendar.component(.hour, from: fire), 9)
                XCTAssertEqual(calendar.component(.day, from: fire), choice == .sameDayMorning ? 5 : 4)
            }
        }
        for (choice, offset) in [(CalendarAlertChoice.atStart, 0.0), (.fifteenMinutes, -900.0), (.oneHour, -3600.0)] {
            let event = CalendarEventRequest(title: "Test", notes: "", start: start,
                end: start.addingTimeInterval(1800), allDay: false, timeZone: calendar.timeZone,
                alert: choice).makeEvent(in: store)
            XCTAssertEqual(event.alarms?.first?.relativeOffset, offset)
            XCTAssertFalse(event.isAllDay)
        }
    }

    func testMorningAlertsUseLocalClockAcrossDaylightSaving() {
        for day in ["2026-03-08", "2026-03-09", "2026-11-01", "2026-11-02"] {
            let start = CalendarDatePolicy.parseDay(day, calendar: calendar)!
            for choice in [CalendarAlertChoice.sameDayMorning, .previousDayMorning] {
                let fire = choice.fireDate(start: start, calendar: calendar)!
                XCTAssertEqual(calendar.component(.hour, from: fire), 9)
                XCTAssertEqual(calendar.component(.minute, from: fire), 0)
                let expectedDay = CalendarDatePolicy.addingDays(choice == .sameDayMorning ? 0 : -1, to: start, calendar: calendar)
                XCTAssertTrue(calendar.isDate(fire, inSameDayAs: expectedDay))
            }
        }
    }

    func testExpandedAlertsAndCustomAbsoluteTime() {
        let start = CalendarDatePolicy.parseDay("2026-03-09", calendar: calendar)!.addingTimeInterval(10 * 3600)
        for (choice, seconds) in [(CalendarAlertChoice.fiveMinutes, 300.0), (.tenMinutes, 600.0), (.thirtyMinutes, 1800.0), (.twoHours, 7200.0)] {
            XCTAssertEqual(choice.fireDate(start: start, calendar: calendar), start.addingTimeInterval(-seconds))
        }
        for (choice, days) in [(CalendarAlertChoice.oneDay, -1), (.twoDays, -2), (.oneWeek, -7)] {
            let fire = choice.fireDate(start: start, calendar: calendar)!
            XCTAssertEqual(calendar.component(.hour, from: fire), 10)
            XCTAssertEqual(calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: fire)).day, days)
        }
        for (choice, days) in [(CalendarAlertChoice.twoDaysMorning, -2), (.weekMorning, -7)] {
            let fire = choice.fireDate(start: start, calendar: calendar)!
            XCTAssertEqual(calendar.component(.hour, from: fire), 9)
            XCTAssertEqual(calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: fire)).day, days)
        }
        let custom = start.addingTimeInterval(-12345)
        for allDay in [true, false] {
            let event = CalendarEventRequest(title: "Test", notes: "", start: start,
                end: start.addingTimeInterval(86400), allDay: allDay, timeZone: calendar.timeZone,
                alert: .custom, customAlertDate: custom).makeEvent(in: EKEventStore())
            XCTAssertEqual(event.alarms?.first?.absoluteDate, custom)
            XCTAssertEqual(event.isAllDay, allDay)
        }
    }

    func testKnownAppointmentExamplePrefillsSourceTimeAndAlert() {
        for day in ["2026-03-05", "2026-10-29", "2026-10-02"] {
            let now = CalendarDatePolicy.parseDay(day, calendar: calendar)!
            for language in [AppLanguage.en, .zh] {
                let proposal = CalendarProposal.testExample(.appointment, language: language, now: now, calendar: calendar)
                let date = proposal.date!
                XCTAssertTrue(proposal.hasAppointmentTime)
                XCTAssertEqual(calendar.component(.hour, from: date), 10)
                XCTAssertEqual(calendar.component(.minute, from: date), 0)
                XCTAssertTrue(calendar.isDate(date, inSameDayAs: CalendarDatePolicy.addingDays(3, to: now, calendar: calendar)))
                let alarm = CalendarAlertChoice.fifteenMinutes.fireDate(start: date, calendar: calendar)!
                XCTAssertEqual(calendar.component(.hour, from: alarm), 9)
                XCTAssertEqual(calendar.component(.minute, from: alarm), 45)
                let deadline = CalendarProposal.testExample(.deadline, language: language, now: now, calendar: calendar)
                XCTAssertFalse(deadline.hasAppointmentTime)
                XCTAssertEqual(calendar.component(.hour, from: deadline.date!), 0)
                XCTAssertNil(CalendarProposal.testExample(.reminder, language: language, now: now, calendar: calendar).date)
            }
        }
    }

    func testExtractedAppointmentTimeFlowsIntoEventAndAlert() throws {
        // Decode the same snake_case fact contract returned by the relay.
        let json = #"[{"id":"day","kind":"appointment_date","raw_text":"October 5, 2026","value":"2026-10-05","currency":null,"status":"confirmed","origin":"letter_fact","label":{"en":"Date","zh":"日期"},"explanation":{"en":"Appointment date","zh":"预约日期"},"source_refs":[{"page":1,"excerpt":"October 5, 2026 at 10 AM America/New_York"}]},{"id":"time","kind":"appointment_time","raw_text":"10 AM","value":"10:00","currency":null,"status":"confirmed","origin":"letter_fact","label":{"en":"Time","zh":"时间"},"explanation":{"en":"Appointment time","zh":"预约时间"},"source_refs":[{"page":1,"excerpt":"10 AM"}]},{"id":"zone","kind":"appointment_timezone","raw_text":"America/New_York","value":"America/New_York","currency":null,"status":"confirmed","origin":"letter_fact","label":{"en":"Zone","zh":"时区"},"explanation":{"en":"Appointment zone","zh":"预约时区"},"source_refs":[{"page":1,"excerpt":"America/New_York"}]}]"#
        let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
        let facts = try decoder.decode([LetterFact].self, from: Data(json.utf8))
        let action = LetterAction(id: "visit", descriptionEn: "Attend visit", descriptionZh: "参加预约", actionKind: "schedule_appointment", status: "confirmed", sourceRefs: [], requirement: "required", condition: nil, amountFactIds: [], deadlineFactId: nil, appointmentFactIds: ["day", "time", "zone"])
        for language in [AppLanguage.en, .zh] {
            let proposal = CalendarProposal.make(action: action, facts: facts, language: language, calendar: calendar)
            XCTAssertTrue(proposal.hasAppointmentTime)
            XCTAssertTrue(proposal.hasSourceTimeZone)
            XCTAssertEqual(proposal.timeZone.identifier, "America/New_York")
            var zone = calendar; zone.timeZone = proposal.timeZone
            let start = try XCTUnwrap(proposal.date)
            XCTAssertEqual(zone.component(.hour, from: start), 10)
            let event = CalendarEventRequest(title: proposal.title, notes: proposal.source, start: start,
                end: start.addingTimeInterval(1800), allDay: false, timeZone: proposal.timeZone, alert: .fifteenMinutes).makeEvent(in: EKEventStore())
            let fire = start.addingTimeInterval(try XCTUnwrap(event.alarms?.first?.relativeOffset))
            XCTAssertEqual(zone.component(.hour, from: fire), 9)
            XCTAssertEqual(zone.component(.minute, from: fire), 45)
            XCTAssertTrue(event.notes?.contains("10 AM") == true)
        }
        let missing = CalendarProposal.make(action: action, facts: [facts[0]], language: .en, calendar: calendar)
        XCTAssertFalse(missing.hasAppointmentTime)
        XCTAssertTrue(missing.requiresVerification)
        let noZone = CalendarProposal.make(action: action, facts: Array(facts.prefix(2)), language: .en, calendar: calendar)
        XCTAssertTrue(noZone.hasAppointmentTime)
        XCTAssertFalse(noZone.hasSourceTimeZone)
        XCTAssertEqual(noZone.timeZone, calendar.timeZone)
        let extra = LetterFact(id: "otherTime", kind: "appointment_time", rawText: "2 PM", value: "14:00", currency: nil, status: "confirmed", origin: "letter_fact", label: facts[1].label, explanation: facts[1].explanation, sourceRefs: facts[1].sourceRefs)
        // An unlinked time cannot overwrite this action's appointment.
        XCTAssertEqual(CalendarProposal.make(action: action, facts: facts + [extra], language: .en, calendar: calendar).date,
                       CalendarProposal.make(action: action, facts: facts, language: .en, calendar: calendar).date)
        let conflicting = LetterAction(id: "visit", descriptionEn: "Visit", descriptionZh: "预约", actionKind: "schedule_appointment", status: "confirmed", sourceRefs: [], requirement: "required", condition: nil, amountFactIds: [], deadlineFactId: nil, appointmentFactIds: ["day", "time", "otherTime"])
        XCTAssertFalse(CalendarProposal.make(action: conflicting, facts: facts + [extra], language: .en, calendar: calendar).hasAppointmentTime)
    }

    func testAppointmentClockRejectsInvalidAndAmbiguousLocalTimes() {
        let normal = CalendarDatePolicy.parseDay("2026-10-05", calendar: calendar)!
        for (text, hour) in [("00:00", 0), ("12:00", 12), ("14:30", 14)] {
            XCTAssertEqual(CalendarDatePolicy.appointmentDate(day: normal, time: text, calendar: calendar).map { calendar.component(.hour, from: $0) }, hour)
        }
        for invalid in ["24:00", "10:60", "10 AM", ""] {
            XCTAssertNil(CalendarDatePolicy.appointmentDate(day: normal, time: invalid, calendar: calendar))
        }
        XCTAssertNil(CalendarDatePolicy.appointmentDate(day: CalendarDatePolicy.parseDay("2026-03-08", calendar: calendar)!, time: "02:30", calendar: calendar))
        XCTAssertNil(CalendarDatePolicy.appointmentDate(day: CalendarDatePolicy.parseDay("2026-11-01", calendar: calendar)!, time: "01:30", calendar: calendar))
    }

    func testSuggestedDurationDecodesAndSetsTimedEventEnd() throws {
        let json = #"{"id":"visit","description_en":"Attend appointment","description_zh":"参加预约","action_kind":"schedule_appointment","status":"confirmed","source_refs":[],"requirement":"required","condition":null,"amount_fact_ids":[],"deadline_fact_id":null,"appointment_fact_ids":["date"],"suggested_duration_minutes":50}"#
        let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
        let action = try decoder.decode(LetterAction.self, from: Data(json.utf8))
        let text = BilingualText(en: "Appointment", zh: "预约")
        let fact = LetterFact(id: "date", kind: "appointment_date", rawText: "October 5, 2026", value: "2026-10-05", currency: nil, status: "confirmed", origin: "letter_fact", label: text, explanation: text, sourceRefs: [.init(page: 1, excerpt: "October 5, 2026")])
        let proposal = CalendarProposal.make(action: action, facts: [fact], language: .en, calendar: calendar)
        XCTAssertEqual(proposal.suggestedDurationMinutes, 50)
        XCTAssertEqual(proposal.initialDurationMinutes, 50)
        let start = try XCTUnwrap(proposal.date)
        let event = CalendarEventRequest(title: "Test", notes: "", start: start,
            end: CalendarDatePolicy.end(start: start, allDay: false, minutes: proposal.initialDurationMinutes, calendar: calendar), allDay: false, timeZone: calendar.timeZone).makeEvent(in: EKEventStore())
        XCTAssertEqual(event.endDate.timeIntervalSince(start), 3000)
        let legacy = json.replacingOccurrences(of: ",\"suggested_duration_minutes\":50", with: "")
        let old = try decoder.decode(LetterAction.self, from: Data(legacy.utf8))
        XCTAssertEqual(CalendarProposal.make(action: old, facts: [fact], language: .en, calendar: calendar).initialDurationMinutes, 30)
        var invalid = action; invalid.suggestedDurationMinutes = 99999
        XCTAssertEqual(CalendarProposal.make(action: invalid, facts: [fact], language: .en, calendar: calendar).initialDurationMinutes, 30)
        let reminder = CalendarProposal.make(action: action, facts: [], language: .en, calendar: calendar)
        XCTAssertNil(reminder.suggestedDurationMinutes)
    }

    func testCustomDurationValidationAndEndAcrossMidnight() {
        for text in ["", "0", "-1", "1.5", "1441", "abc"] { XCTAssertNil(CalendarDurationPolicy.custom(text)) }
        XCTAssertEqual(CalendarDurationPolicy.custom(" 75 "), 75)
        XCTAssertEqual(CalendarDurationPolicy.custom("1440"), 1440)
        let day = CalendarDatePolicy.parseDay("2026-10-05", calendar: calendar)!
        let start = day.addingTimeInterval(23 * 3600)
        let end = CalendarDatePolicy.end(start: start, allDay: false, minutes: 125, calendar: calendar)
        XCTAssertEqual(calendar.component(.day, from: end), 6)
        XCTAssertEqual(calendar.component(.hour, from: end), 1)
        XCTAssertEqual(calendar.component(.minute, from: end), 5)
    }

    @MainActor func testDirectSavePermissionFailuresSuccessAndDuplicateGuard() async {
        let writer = FakeCalendarWriter()
        let suite = "calendar-save-test-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = CalendarSaveModel(writer: writer, defaults: defaults)
        let start = Date()
        let request = CalendarEventRequest(title: "Fictional", notes: "", start: start, end: start.addingTimeInterval(1800), allDay: false, timeZone: .current)
        writer.allowed = false
        let denied = await model.save(request)
        XCTAssertFalse(denied); XCTAssertEqual(model.failure, .permissionDenied); XCTAssertEqual(writer.saves, 0)
        writer.allowed = true; writer.failure = .unavailable
        let unavailable = await model.save(request)
        XCTAssertFalse(unavailable); XCTAssertEqual(model.failure, .unavailable)
        writer.failure = .failed
        let failed = await model.save(request)
        XCTAssertFalse(failed); XCTAssertEqual(model.failure, .failed); XCTAssertFalse(model.didSave)
        XCTAssertFalse(defaults.bool(forKey: "calendarSavePending"))
        writer.failure = nil
        let saved = await model.save(request)
        XCTAssertTrue(saved); XCTAssertTrue(model.didSave); XCTAssertNil(model.failure)
        let attempts = writer.saves
        let duplicate = await model.save(request)
        XCTAssertFalse(duplicate); XCTAssertEqual(writer.saves, attempts)
        XCTAssertFalse(model.isSaving)
    }

    @MainActor func testConcurrentAddDoesNotSaveTwice() async {
        let writer = FakeCalendarWriter(); writer.pause = true
        let model = CalendarSaveModel(writer: writer)
        let request = CalendarEventRequest(title: "Fictional", notes: "", start: Date(), end: Date().addingTimeInterval(1800), allDay: false, timeZone: .current)
        let first = Task { await model.save(request) }
        while writer.continuation == nil { await Task.yield() }
        let second = await model.save(request)
        XCTAssertFalse(second); XCTAssertTrue(model.isSaving)
        writer.continuation?.resume(returning: true)
        let saved = await first.value
        XCTAssertTrue(saved); XCTAssertEqual(writer.saves, 1)
    }

    func testCalendarNotesAreEventBriefsAndPreserveConditions() throws {
        let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
        let json = #"{"id":"visit","description_en":"Attend appointment","description_zh":"参加预约","action_kind":"schedule_appointment","status":"confirmed","source_refs":[],"requirement":"conditional","condition":{"en":"If changing plans","zh":"如需更换计划"},"amount_fact_ids":[],"deadline_fact_id":"due","appointment_fact_ids":[],"calendar_notes":{"en":"Submit the insurance form to the office.","zh":"向办公室提交保险表格。"}}"#
        let action = try decoder.decode(LetterAction.self, from: Data(json.utf8))
        let label = BilingualText(en: "Deadline", zh: "截止时间")
        let deadline = LetterFact(id: "due", kind: "deadline", rawText: "October 5 by 5 PM", value: "2026-10-05", currency: nil, status: "confirmed", origin: "letter_fact", label: label, explanation: label, sourceRefs: [])
        let en = CalendarNoteBuilder.make(action: action, deadline: deadline, language: .en)
        XCTAssertTrue(en.hasPrefix("Submit the insurance form to the office."))
        XCTAssertTrue(en.contains("If changing plans")); XCTAssertTrue(en.contains("October 5 by 5 PM"))
        let zh = CalendarNoteBuilder.make(action: action, deadline: deadline, language: .zh)
        XCTAssertTrue(zh.hasPrefix("向办公室提交保险表格。")); XCTAssertTrue(zh.contains("如需更换计划"))
        var legacy = action; legacy.calendarNotes = nil
        XCTAssertTrue(CalendarNoteBuilder.make(action: legacy, deadline: deadline, language: .en).hasPrefix("Attend appointment"))
        for language in [AppLanguage.en, .zh] {
            let example = CalendarProposal.testExample(.appointment, language: language)
            XCTAssertFalse(example.eventNotes.isEmpty)
            XCTAssertFalse(example.eventNotes.contains("Verify"))
            XCTAssertFalse(example.eventNotes.contains("AI"))
            XCTAssertFalse(example.eventNotes.contains("核对"))
            XCTAssertFalse(example.eventNotes.contains("Date as stated"))
            let start = example.date!
            let event = CalendarEventRequest(title: example.title, notes: example.eventNotes, start: start, end: start.addingTimeInterval(3600), allDay: false, timeZone: example.timeZone).makeEvent(in: EKEventStore())
            XCTAssertEqual(event.notes, example.eventNotes)
        }
    }

    func testBillCalendarDeduplicatesSourceAndDateOnlyNotes() {
        let excerpt = "Please pay USD 125.00 by November 15, 2026."
        let text = BilingualText(en: "Payment due", zh: "付款截止")
        let due = LetterFact(id: "due", kind: "deadline", rawText: excerpt, value: "2026-11-15", currency: nil, status: "confirmed", origin: "letter_fact", label: text, explanation: text, sourceRefs: [.init(page: 1, excerpt: excerpt)])
        let amount = LetterFact(id: "amount", kind: "amount", rawText: "USD 125.00", value: "125.00", currency: "USD", status: "confirmed", origin: "letter_fact", label: text, explanation: text, sourceRefs: [.init(page: 1, excerpt: excerpt)])
        var action = LetterAction(id: "pay", descriptionEn: "Pay the 125.00 USD balance by November 15, 2026.", descriptionZh: "在 2026 年 11 月 15 日前支付 125 美元。", actionKind: "payment", status: "confirmed", sourceRefs: [.init(page: 1, excerpt: excerpt), .init(page: 1, excerpt: "  Please pay USD 125.00 by November 15, 2026.  ")], requirement: "required", condition: nil, amountFactIds: ["amount"], deadlineFactId: "due", appointmentFactIds: [])
        action.calendarNotes = BilingualText(en: "Pay USD 125.00 to Harbor Example Clinic.", zh: "向 Harbor Example Clinic 支付 125 美元。")
        let fallback = CalendarProposal.make(action: action, facts: [due, amount], language: .en, calendar: calendar)
        XCTAssertEqual(fallback.title, "Pay bill · USD 125.00")
        XCTAssertEqual(fallback.source.components(separatedBy: "Photo 1:").count - 1, 1)
        XCTAssertNil(fallback.sourceDate)
        XCTAssertEqual(fallback.eventNotes, "Pay USD 125.00 to Harbor Example Clinic.")
        XCTAssertEqual(fallback.date, CalendarDatePolicy.parseDay("2026-11-15", calendar: calendar))
        action.calendarTitle = BilingualText(en: "Pay Harbor Example Clinic", zh: "支付诊所账单")
        XCTAssertEqual(CalendarProposal.make(action: action, facts: [due, amount], language: .zh, calendar: calendar).title, "支付诊所账单")
        // Repeated evidence on different pages retains both page references.
        let secondPage = LetterFact(id: "due", kind: "deadline", rawText: excerpt, value: "2026-11-15", currency: nil, status: "confirmed", origin: "letter_fact", label: text, explanation: text, sourceRefs: [.init(page: 2, excerpt: excerpt)])
        XCTAssertTrue(CalendarProposal.make(action: action, facts: [secondPage], language: .en, calendar: calendar).source.contains("Photo 2:"))
        let cutoff = LetterFact(id: "due", kind: "deadline", rawText: "Received by November 15 at 5 PM", value: "2026-11-15", currency: nil, status: "confirmed", origin: "letter_fact", label: text, explanation: text, sourceRefs: [])
        XCTAssertTrue(CalendarNoteBuilder.make(action: action, deadline: cutoff, language: .en).contains("5 PM"))
    }

    func testBillContextSurvivesGenericAICalendarText() throws {
        let summary = LetterSummary(whatThisIs: "Medical bill", whatToNote: "Example", whatToDo: "Pay", when: "Due", factIds: [], actionIds: [])
        let document = LetterInterpretation(schemaVersion: 1, domain: "medical", recipient: nil, organization: "Harbor Example Clinic", category: "bills", needsReview: false, facts: [], actions: [], summaries: LetterSummaries(en: summary, zh: summary))
        let text = BilingualText(en: "Payment", zh: "付款")
        let due = LetterFact(id: "due", kind: "deadline", rawText: "Pay by November 15, 2026", value: "2026-11-15", currency: nil, status: "confirmed", origin: "letter_fact", label: text, explanation: text, sourceRefs: [])
        let amount = LetterFact(id: "amount", kind: "amount", rawText: "USD 125.00", value: "125.00", currency: "USD", status: "confirmed", origin: "letter_fact", label: text, explanation: text, sourceRefs: [])
        var action = LetterAction(id: "pay", descriptionEn: "Pay balance", descriptionZh: "支付余额", actionKind: "payment", status: "confirmed", sourceRefs: [], requirement: "required", condition: nil, amountFactIds: ["amount"], deadlineFactId: "due", appointmentFactIds: [])
        action.calendarTitle = BilingualText(en: "Pay bill", zh: "支付账单")
        action.calendarNotes = BilingualText(en: "Pay the balance.", zh: "支付余额。")
        for language in [AppLanguage.en, .zh] {
            let proposal = CalendarProposal.make(action: action, facts: [due, amount], language: language, calendar: calendar, document: document)
            XCTAssertTrue(proposal.title.contains("Harbor Example Clinic"))
            XCTAssertTrue(proposal.title.contains(language == .en ? "Medical bill" : "医疗账单"))
            XCTAssertTrue(proposal.eventNotes.contains("Harbor Example Clinic"))
            XCTAssertTrue(proposal.eventNotes.contains("USD 125.00"))
            let original = try XCTUnwrap(proposal.date)
            XCTAssertEqual(proposal.notes(for: original, calendar: calendar, language: language), proposal.eventNotes)
            let changed = CalendarDatePolicy.addingDays(-1, to: original, calendar: calendar)
            XCTAssertTrue(proposal.notes(for: changed, calendar: calendar, language: language).contains("2026-11-15"))
        }
        let eob = LetterInterpretation(schemaVersion: 1, domain: "insurance", recipient: nil, organization: "Example insurer", category: "insurance_explanations", needsReview: false, facts: [], actions: [], summaries: document.summaries)
        XCTAssertNil(CalendarNoteBuilder.billContext(eob, language: .en))
        // Without classified source context, no provider or bill type is invented.
        XCTAssertEqual(CalendarNoteBuilder.contextualTitle(action: action, facts: [], language: .en, document: nil), "Pay bill")
    }

    func testEverydayBillHeadingAndCalendarPreserveProviderAndLinkedAmount() throws {
        let summary = LetterSummary(whatThisIs: "Electricity bill", whatToNote: "", whatToDo: "Pay", when: "Due", factIds: [], actionIds: [])
        let document = LetterInterpretation(schemaVersion: 1, domain: "billing", recipient: nil, organization: "Example Electric", category: "bills", needsReview: false, facts: [], actions: [], summaries: LetterSummaries(en: summary, zh: summary))
        let decoded = try JSONDecoder().decode(LetterInterpretation.self, from: JSONEncoder().encode(document))
        XCTAssertEqual(decoded.domain, "billing")
        XCTAssertEqual(decoded.heading(.en), "This is a bill or fee notice")
        XCTAssertEqual(decoded.heading(.zh), "这是一份账单或费用通知")
        let text = BilingualText(en: "Amount due", zh: "应付金额")
        let amount = LetterFact(id: "dueAmount", kind: "amount", rawText: "USD 84.20", value: "84.20", currency: "USD", status: "confirmed", origin: "letter_fact", label: text, explanation: text, sourceRefs: [])
        var action = LetterAction(id: "pay", descriptionEn: "Pay electricity bill", descriptionZh: "支付电费账单", actionKind: "payment", status: "confirmed", sourceRefs: [], requirement: "required", condition: nil, amountFactIds: ["dueAmount"], deadlineFactId: nil, appointmentFactIds: [])
        action.calendarTitle = BilingualText(en: "Pay electricity bill", zh: "支付电费账单")
        action.calendarNotes = BilingualText(en: "Pay the electricity balance.", zh: "支付电费余额。")
        for language in [AppLanguage.en, .zh] {
            let proposal = CalendarProposal.make(action: action, facts: [amount], language: language, calendar: calendar, document: document)
            XCTAssertEqual(proposal.kind, .reminder)
            XCTAssertNil(proposal.date)
            XCTAssertTrue(proposal.title.contains(language == .en ? "electricity" : "电费"))
            XCTAssertTrue(proposal.title.contains("Example Electric"))
            XCTAssertTrue(proposal.title.contains("USD 84.20"))
            XCTAssertTrue(proposal.eventNotes.contains("Example Electric"))
            XCTAssertTrue(proposal.eventNotes.contains("USD 84.20"))
            XCTAssertFalse(proposal.title.contains("medical"))
            XCTAssertFalse(proposal.title.contains("保险"))
        }
    }

    func testBankStatementsDoNotMislabelBalancesAndCardCalendarUsesMinimumPayment() throws {
        let summary = LetterSummary(whatThisIs: "Bank statement", whatToNote: "", whatToDo: "", when: "", factIds: [], actionIds: [])
        let account = LetterInterpretation(schemaVersion: 1, domain: "banking", recipient: nil, organization: "Example Bank", category: nil, needsReview: true, facts: [], actions: [], summaries: LetterSummaries(en: summary, zh: summary))
        XCTAssertEqual(account.heading(.en), "This is a bank or credit-card statement")
        XCTAssertEqual(account.heading(.zh), "这是一份银行或信用卡账单")
        XCTAssertNil(CalendarNoteBuilder.billContext(account, language: .en))
        let card = LetterInterpretation(schemaVersion: 1, domain: "banking", recipient: nil, organization: "Example Card Bank", category: "bills", needsReview: false, facts: [], actions: [], summaries: account.summaries)
        let text = BilingualText(en: "Minimum payment", zh: "最低还款额")
        let minimum = LetterFact(id: "minimum", kind: "amount", rawText: "USD 35.00", value: "35.00", currency: "USD", status: "confirmed", origin: "letter_fact", label: text, explanation: text, sourceRefs: [])
        let balance = LetterFact(id: "balance", kind: "amount", rawText: "USD 1200.00", value: "1200.00", currency: "USD", status: "confirmed", origin: "letter_fact", label: text, explanation: text, sourceRefs: [])
        let due = LetterFact(id: "due", kind: "deadline", rawText: "Pay by November 22, 2026", value: "2026-11-22", currency: nil, status: "confirmed", origin: "letter_fact", label: text, explanation: text, sourceRefs: [])
        var action = LetterAction(id: "pay", descriptionEn: "Pay minimum", descriptionZh: "支付最低还款额", actionKind: "payment", status: "confirmed", sourceRefs: [], requirement: "required", condition: nil, amountFactIds: ["minimum"], deadlineFactId: "due", appointmentFactIds: [])
        action.calendarTitle = BilingualText(en: "Pay minimum credit-card payment", zh: "支付信用卡最低还款额")
        action.calendarNotes = BilingualText(en: "Pay the required minimum, not the full statement balance.", zh: "支付规定的最低还款额，并非全额账单余额。")
        for language in [AppLanguage.en, .zh] {
            let proposal = CalendarProposal.make(action: action, facts: [minimum,balance,due], language: language, calendar: calendar, document: card)
            XCTAssertEqual(proposal.kind, .deadline)
            XCTAssertEqual(proposal.date, CalendarDatePolicy.parseDay("2026-11-22", calendar: calendar))
            XCTAssertTrue(proposal.title.contains("USD 35.00"))
            XCTAssertFalse(proposal.title.contains("1200.00"))
            XCTAssertTrue(proposal.title.contains("Example Card Bank"))
            XCTAssertTrue(proposal.title.contains(language == .en ? "minimum" : "最低"))
        }
    }

    func testChangingTimeZonePreservesUserSelectedDayAndClock() throws {
        let date = try XCTUnwrap(CalendarDatePolicy.parseDay("2026-11-15", calendar: calendar))
        let timed = try XCTUnwrap(CalendarDatePolicy.appointmentDate(day: date, time: "10:30", calendar: calendar))
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        var target = calendar; target.timeZone = tokyo
        let day = CalendarDatePolicy.changingZone(date, from: calendar.timeZone, to: tokyo)
        XCTAssertEqual(target.dateComponents([.year, .month, .day], from: day), calendar.dateComponents([.year, .month, .day], from: date))
        let changed = CalendarDatePolicy.changingZone(timed, from: calendar.timeZone, to: tokyo)
        XCTAssertEqual(target.component(.hour, from: changed), 10)
        XCTAssertEqual(target.component(.minute, from: changed), 30)
    }

    func testCalendarStrictDatesDoNotNormalizeInvalidInput() {
        XCTAssertNil(CalendarDatePolicy.parseDay("2026-02-30", calendar: calendar))
        XCTAssertNil(CalendarDatePolicy.parseDay("11/12", calendar: calendar))
        XCTAssertNil(CalendarDatePolicy.parseDay("2026-11-15T12:00:00Z", calendar: calendar))
        XCTAssertNotNil(CalendarDatePolicy.parseDay("2028-02-29", calendar: calendar))
    }
    func testCalendarAllDayEndUsesLocalDayAcrossDST() {
        let spring = CalendarDatePolicy.parseDay("2026-03-08", calendar: calendar)!
        let fall = CalendarDatePolicy.parseDay("2026-11-01", calendar: calendar)!
        XCTAssertEqual(CalendarDatePolicy.end(start: spring, allDay: true, minutes: 30, calendar: calendar).timeIntervalSince(spring), 23 * 3600)
        XCTAssertEqual(CalendarDatePolicy.end(start: fall, allDay: true, minutes: 30, calendar: calendar).timeIntervalSince(fall), 25 * 3600)
        XCTAssertEqual(CalendarDatePolicy.end(start: spring, allDay: false, minutes: 45, calendar: calendar).timeIntervalSince(spring), 45 * 60)
    }
    func testCalendarMidnightRequiresReviewAgain() {
        let start = CalendarDatePolicy.parseDay("2026-10-02", calendar: calendar)!
        XCTAssertFalse(CalendarDatePolicy.reviewExpired(reviewedDay: start, now: start.addingTimeInterval(23 * 3600), calendar: calendar))
        XCTAssertTrue(CalendarDatePolicy.reviewExpired(reviewedDay: start, now: CalendarDatePolicy.addingDays(1, to: start, calendar: calendar), calendar: calendar))
    }
    func testCalendarPreservesPastWeekendDeadlineAndConditions() {
        let text = BilingualText(en: "If changing plans", zh: "如果更换计划")
        let fact = LetterFact(id: "due", kind: "deadline", rawText: "By September 27, 2026 at 5pm", value: "2026-09-27", currency: nil, status: "confirmed", origin: "letter_fact", label: text, explanation: text, sourceRefs: [.init(page: 1, excerpt: "By September 27, 2026 at 5pm")])
        let action = LetterAction(id: "act", descriptionEn: "Submit", descriptionZh: "提交", actionKind: "submit", status: "confirmed", sourceRefs: [], requirement: "conditional", condition: text, amountFactIds: [], deadlineFactId: "due", appointmentFactIds: [])
        let proposal = CalendarProposal.make(action: action, facts: [fact], language: .zh, now: CalendarDatePolicy.parseDay("2026-10-02", calendar: calendar)!, calendar: calendar)
        XCTAssertEqual(proposal.kind, .deadline)
        XCTAssertEqual(proposal.date, CalendarDatePolicy.parseDay("2026-09-27", calendar: calendar))
        XCTAssertEqual(proposal.condition, "如果更换计划")
        XCTAssertTrue(proposal.source.contains("5pm"))
    }
    func testCalendarUncertainDeadlineIsNotPrefilled() {
        let text = BilingualText(en: "Date", zh: "日期")
        let fact = LetterFact(id: "due", kind: "deadline", rawText: "November ?", value: "2026-11-15", currency: nil, status: "needs_verification", origin: "letter_fact", label: text, explanation: text, sourceRefs: [])
        let action = LetterAction(id: "act", descriptionEn: "Pay", descriptionZh: "支付", actionKind: "payment", status: "confirmed", sourceRefs: [], requirement: "required", condition: nil, amountFactIds: [], deadlineFactId: "due", appointmentFactIds: [])
        let proposal = CalendarProposal.make(action: action, facts: [fact], language: .en, calendar: calendar)
        XCTAssertNil(proposal.date)
        XCTAssertTrue(proposal.requiresVerification)
        XCTAssertEqual(proposal.kind, .deadline)
    }
    func testCalendarEffectiveDateCannotBecomeDeadline() {
        let text = BilingualText(en: "Date", zh: "日期")
        let fact = LetterFact(id: "effective", kind: "effective_date", rawText: "Coverage begins", value: "2026-11-15", currency: nil, status: "confirmed", origin: "letter_fact", label: text, explanation: text, sourceRefs: [])
        let action = LetterAction(id: "act", descriptionEn: "Call", descriptionZh: "致电", actionKind: "call", status: "confirmed", sourceRefs: [], requirement: "optional", condition: nil, amountFactIds: [], deadlineFactId: nil, appointmentFactIds: [])
        let proposal = CalendarProposal.make(action: action, facts: [fact], language: .en, calendar: calendar)
        XCTAssertEqual(proposal.kind, .reminder)
        XCTAssertNil(proposal.date)
    }
    func testOnlyAcceptedPhotoCanReachInterpretation() {
        for phase in [CapturePhase.ready, .checking, .retake, .checkFailed, .interpreting, .complete] {
            XCTAssertFalse(phase.canInterpret)
        }
        XCTAssertTrue(CapturePhase.valid.canInterpret)
        XCTAssertTrue(CapturePhase.interpretFailed.canInterpret)
    }
    func testDebugTransportCannotTargetPublicHosts() {
        XCTAssertTrue(RelayConfiguration.isLocalHost("127.0.0.1"))
        XCTAssertTrue(RelayConfiguration.isLocalHost("192.168.1.4"))
        XCTAssertFalse(RelayConfiguration.isLocalHost("api.openai.com"))
        XCTAssertFalse(RelayConfiguration.isLocalHost("172.32.0.1"))
        XCTAssertFalse(RelayConfiguration.isLocalHost("192.168.1.4.evil.com"))
    }
    func testValidationContractDecodesWithoutLosingGate() throws {
        let json = #"{"verdict":"retake","reason":{"en":"Retake","zh":"请重拍"},"validation_token":null}"#
        let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(PageValidation.self, from: Data(json.utf8))
        XCTAssertNil(result.validationToken)
        XCTAssertEqual(result.reason.text(.zh), "请重拍")
    }
    func testContextualFactsAndConditionalActionsDecodeInBothLanguages() throws {
        let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
        let factJSON = #"{"id":"effective","kind":"effective_date","raw_text":"Coverage begins January 1, 2027","value":"2027-01-01","currency":null,"status":"confirmed","origin":"letter_fact","label":{"en":"Coverage begins","zh":"保障生效日期"},"explanation":{"en":"Coverage starts on this date, not an action deadline.","zh":"这是保障开始日期，不是办理截止日期。"},"source_refs":[{"page":1,"excerpt":"Coverage begins January 1, 2027"}]}"#
        let fact = try decoder.decode(LetterFact.self, from: Data(factJSON.utf8))
        XCTAssertEqual(fact.kind, "effective_date")
        XCTAssertEqual(fact.label.text(.zh), "保障生效日期")
        XCTAssertTrue(fact.explanation.text(.en).contains("not an action deadline"))
        let actionJSON = #"{"id":"choose","description_en":"Submit a selection","description_zh":"提交选择","action_kind":"administration","status":"confirmed","requirement":"conditional","condition":{"en":"If you want to change plans","zh":"如果你想更换计划"},"source_refs":[{"page":1,"excerpt":"If you want to change plans, submit a selection"}],"amount_fact_ids":[],"deadline_fact_id":null,"appointment_fact_ids":[]}"#
        let action = try decoder.decode(LetterAction.self, from: Data(actionJSON.utf8))
        XCTAssertEqual(action.requirement, "conditional")
        XCTAssertEqual(action.condition?.text(.zh), "如果你想更换计划")
        XCTAssertNil(action.deadlineFactId)
    }
    @MainActor func testNewCaptureDiscardsPriorSessionAndUnblocksControls() {
        let model = CaptureModel()
        model.changeLanguage(.zh)
        model.reset()
        XCTAssertEqual(model.phase, .ready)
        XCTAssertNil(model.image)
        XCTAssertNil(model.result)
        XCTAssertEqual(model.language, .zh)
    }
}

private final class StubAPI: LetterAPIClient {
    let isConfigured = true
    var shouldReject = false
    var shouldFail = false
    var failureCode = "provider_not_configured"
    var validationCalls = 0
    var interpretationCalls = 0
    var submittedPages: [LetterPageInput] = []
    var captureIDs: [UUID] = []
    func validate(image: Data, captureID: UUID, pageID: UUID) async throws -> PageValidation {
        validationCalls += 1
        captureIDs.append(captureID)
        if shouldFail { throw RelayError(code: failureCode) }
        return PageValidation(verdict: shouldReject ? "retake" : "valid", reason: BilingualText(en: "Photo checked", zh: "照片已检查"), validationToken: shouldReject ? nil : "test-token")
    }
    func interpret(pages: [LetterPageInput], captureID: UUID) async throws -> LetterInterpretation {
        interpretationCalls += 1; submittedPages = pages
        throw RelayError(code: shouldFail ? failureCode : "provider_unavailable")
    }
    func interpret(image: Data, captureID: UUID, pageID: UUID, token: String) async throws -> LetterInterpretation {
        interpretationCalls += 1
        throw RelayError(code: shouldFail ? failureCode : "provider_unavailable")
    }
}
extension LetterAssistantTests {
    @MainActor private func photo(color: UIColor = .white) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 900, height: 1200)).image { ctx in
            color.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 900, height: 1200))
        }
    }
    @MainActor private func waitForWork(_ model: CaptureModel) async throws {
        for _ in 0..<100 where model.phase.busy { try await Task.sleep(nanoseconds: 10_000_000) }
        XCTAssertFalse(model.phase.busy)
    }
    @MainActor func testDeletingPagesPreservesOrderAndReturnsToStartWhenEmpty() async throws {
        let api = StubAPI(); let model = CaptureModel(api: api, inspect: { _ in })
        for index in 0..<3 {
            model.accept(photo(), asNextPage: index > 0); try await waitForWork(model)
        }
        let originals = model.pages
        model.selectPage(1); model.removeCurrentPage()
        XCTAssertEqual(model.pages.map(\.id), [originals[0].id, originals[2].id])
        XCTAssertEqual(model.currentPageIndex, 1)
        XCTAssertEqual(model.pages[1].bytes, originals[2].bytes)
        XCTAssertTrue(model.canFinishCapture)
        model.interpret(); try await waitForWork(model)
        XCTAssertEqual(api.submittedPages.map(\.id), [originals[0].id, originals[2].id])
        model.removeCurrentPage()
        XCTAssertEqual(model.currentPageIndex, 0)
        XCTAssertEqual(model.pages.map(\.id), [originals[0].id])
        model.removeCurrentPage()
        XCTAssertEqual(model.phase, .ready)
        XCTAssertTrue(model.pages.isEmpty)
        XCTAssertNil(model.image)
        XCTAssertFalse(model.canFinishCapture)
    }
    @MainActor func testDeletingPageFreesCapacityButIsBlockedDuringWork() async throws {
        let model = CaptureModel(api: StubAPI(), inspect: { _ in })
        for index in 0..<10 {
            model.accept(photo(), asNextPage: index > 0)
            model.removeCurrentPage()
            XCTAssertEqual(model.pages.count, index + 1)
            try await waitForWork(model)
        }
        XCTAssertFalse(model.canAddPage)
        model.selectPage(0); model.removeCurrentPage()
        XCTAssertEqual(model.pages.count, 9)
        XCTAssertTrue(model.canAddPage)
        XCTAssertEqual(model.currentPageIndex, 0)
    }
    @MainActor func testPDFImportRendersEveryPageAndEnforcesLimit() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pdf")
        defer { try? FileManager.default.removeItem(at: url) }
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let data = renderer.pdfData { context in
            for number in 1...2 {
                context.beginPage()
                let text = "Medical bill page \(number)\nHarbor Example Clinic\nPlease pay USD 125.00 by November 15, 2026.\nContact the clinic if you have questions about this balance."
                (text as NSString).draw(in: CGRect(x: 40, y: 60, width: 532, height: 500), withAttributes: [.font: UIFont.systemFont(ofSize: 24), .foregroundColor: UIColor.black])
            }
        }
        try data.write(to: url)
        let images = try LetterFileImport.images(from: url)
        XCTAssertEqual(images.count, 2)
        for image in images { try PageQualityService.inspect(PageQualityService.prepare(image).bytes) }
        XCTAssertThrowsError(try LetterFileImport.images(from: url, maximumPages: 1)) {
            XCTAssertEqual(($0 as? RelayError)?.code, "too_many_pages")
        }
    }
    @MainActor func testDocumentImportPreservesEveryPageAndFailedPreparationIsAtomic() async throws {
        let model = CaptureModel(api: StubAPI(), inspect: { _ in })
        await model.acceptDocument([photo(), photo(color: .yellow)])
        XCTAssertEqual(model.pages.count, 2)
        XCTAssertTrue(model.canFinishCapture)
        let ids = model.pages.map(\.id)
        let tiny = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { _ in }
        await model.acceptDocument([photo(), tiny])
        XCTAssertEqual(model.pages.map(\.id), ids)
        let unreadable = CaptureModel(api: StubAPI(), inspect: { _ in throw RelayError(code: "photo_unreadable") })
        await unreadable.acceptDocument([photo(), photo()])
        XCTAssertEqual(unreadable.pages.count, 2)
        XCTAssertEqual(unreadable.currentPageIndex, 0)
        XCTAssertFalse(unreadable.canFinishCapture)
    }
    @MainActor func testRejectedPhotoCannotCallInterpretation() async throws {
        let api = StubAPI(); api.shouldReject = true
        let model = CaptureModel(api: api, inspect: { _ in throw RelayError(code: "photo_unreadable") })
        model.accept(photo()); try await waitForWork(model)
        XCTAssertEqual(model.phase, .retake)
        model.interpret()
        XCTAssertEqual(api.interpretationCalls, 0)
        XCTAssertNotNil(model.image)
    }
    @MainActor func testMissingProviderRetainsPhotoAndRetryUsesValidationAgain() async throws {
        let api = StubAPI(); api.shouldFail = true
        let model = CaptureModel(api: api, inspect: { _ in })
        model.accept(photo()); try await waitForWork(model)
        XCTAssertEqual(model.phase, .valid)
        XCTAssertNotNil(model.image)
        XCTAssertNil(model.result)
        api.shouldFail = false
        model.validate(); try await waitForWork(model)
        XCTAssertEqual(model.phase, .valid)
        XCTAssertEqual(api.validationCalls, 0)
        model.interpret(); try await waitForWork(model)
        XCTAssertEqual(model.phase, .interpretFailed)
        model.changeLanguage(.zh)
        XCTAssertTrue(model.message.contains("未能完成此步骤"))
        XCTAssertNotEqual(model.message, "照片已检查")
        XCTAssertNotNil(model.image)
        XCTAssertNil(model.result)
    }
    @MainActor func testRejectedAPIKeyShowsActionableMessageAndKeepsPhoto() async throws {
        let api = StubAPI(); api.shouldFail = true; api.failureCode = "provider_auth_failed"
        let model = CaptureModel(api: api, inspect: { _ in })
        model.changeLanguage(.zh)
        model.accept(photo()); try await waitForWork(model)
        XCTAssertEqual(model.phase, .valid)
        XCTAssertEqual(api.validationCalls, 0)
        model.interpret(); try await waitForWork(model)
        XCTAssertEqual(model.phase, .interpretFailed)
        XCTAssertTrue(model.message.contains("密钥无效"))
        XCTAssertNotNil(model.image)
        XCTAssertNil(model.result)
        model.changeLanguage(.en)
        XCTAssertTrue(model.message.contains("key was rejected"))
    }
    @MainActor func testNextPageAndRetakePreserveOrderAndSubmitEveryOriginal() async throws {
        let api = StubAPI(); let model = CaptureModel(api: api, inspect: { _ in })
        model.accept(photo()); try await waitForWork(model)
        let originalID = model.pages[0].id
        let originalBytes = model.pages[0].bytes
        model.accept(photo(), asNextPage: true); try await waitForWork(model)
        XCTAssertEqual(model.pages.count, 2)
        XCTAssertEqual(model.pages[0].id, originalID)
        XCTAssertEqual(api.validationCalls, 0)
        let secondID = model.pages[1].id
        model.selectPage(0)
        model.accept(photo(color: .black)); try await waitForWork(model)
        XCTAssertEqual(model.pages[0].id, originalID)
        XCTAssertNotEqual(model.pages[0].bytes, originalBytes)
        XCTAssertEqual(model.pages[1].id, secondID)
        model.interpret(); try await waitForWork(model)
        XCTAssertEqual(api.submittedPages.map(\.id), model.pages.map(\.id))
        XCTAssertEqual(api.submittedPages.map(\.image), model.pages.map(\.bytes))
        XCTAssertEqual(model.pages.count, 2)
        XCTAssertEqual(model.phase, .interpretFailed)
        model.interpret(); try await waitForWork(model)
        XCTAssertEqual(api.interpretationCalls, 2)
        model.reset(); XCTAssertTrue(model.pages.isEmpty)
    }
    @MainActor func testRejectedNextPageBlocksWholeLetterWithoutDiscardingEarlierPage() async throws {
        let api = StubAPI(); let model = CaptureModel(api: api, inspect: { data in
            if [CGFloat(1000), 2000, 3000].contains(UIImage(data: data)?.size.width ?? 0) { throw RelayError(code: "photo_unreadable") }
        })
        model.accept(photo()); try await waitForWork(model)
        let firstID = model.pages[0].id
        let unreadable = UIGraphicsImageRenderer(size: CGSize(width: 1000, height: 1200)).image { _ in }
        model.accept(unreadable, asNextPage: true); try await waitForWork(model)
        XCTAssertEqual(model.pages.count, 2)
        XCTAssertEqual(model.pages[0].id, firstID)
        XCTAssertFalse(model.canFinishCapture)
        model.selectPage(0); model.interpret()
        XCTAssertEqual(api.interpretationCalls, 0)
        XCTAssertFalse(model.canAddPage)
        model.selectPage(1); api.shouldReject = false
        model.accept(photo()); try await waitForWork(model)
        XCTAssertTrue(model.canFinishCapture)
    }
    @MainActor func testUncertainPhotoRequiresExplicitChoiceAndPreservesImage() async throws {
        let api = StubAPI()
        let model = CaptureModel(api: api, inspect: { _ in throw RelayError(code: "photo_quality_uncertain") })
        model.accept(photo()); try await waitForWork(model)
        let bytes = model.pages[0].bytes
        XCTAssertFalse(model.canFinishCapture)
        XCTAssertEqual(model.validation?.verdict, "uncertain")
        model.selectPage(0)
        model.changeLanguage(.zh)
        XCTAssertTrue(model.message.contains("仍然使用"))
        model.usePhotoAnyway()
        XCTAssertTrue(model.canFinishCapture)
        XCTAssertEqual(model.pages[0].bytes, bytes)
        XCTAssertEqual(api.validationCalls, 0)
        model.accept(photo()); try await waitForWork(model)
        XCTAssertFalse(model.canFinishCapture)
        XCTAssertEqual(model.validation?.verdict, "uncertain")
    }
    @MainActor func testUnreadablePhotoCannotBeOverridden() async throws {
        let model = CaptureModel(api: StubAPI(), inspect: { _ in throw RelayError(code: "photo_unreadable") })
        model.accept(photo()); try await waitForWork(model)
        model.usePhotoAnyway()
        XCTAssertFalse(model.canFinishCapture)
    }
    @MainActor func testMotionBlurredLetterRequiresRetake() throws {
        let path = try XCTUnwrap(Bundle.main.url(forResource: "fictional-bill", withExtension: "jpg"))
        let source = try XCTUnwrap(CIImage(contentsOf: path))
        let blurred = source.applyingFilter("CIMotionBlur", parameters: ["inputRadius": 8, "inputAngle": 0.3])
        let image = try XCTUnwrap(CIContext().createCGImage(blurred, from: source.extent))
        let prepared = try PageQualityService.prepare(UIImage(cgImage: image))
        XCTAssertThrowsError(try PageQualityService.inspect(prepared.bytes)) { error in
            XCTAssertTrue(["photo_unreadable", "photo_quality_uncertain"].contains((error as? RelayError)?.code ?? ""))
        }
    }
    @MainActor func testFictionalImagePassesLocalReadabilityAndPreservesPixels() throws {
        let path = try XCTUnwrap(Bundle.main.url(forResource: "fictional-bill", withExtension: "jpg"))
        let source = try XCTUnwrap(UIImage(contentsOfFile: path.path))
        let prepared = try PageQualityService.prepare(source)
        XCTAssertEqual(prepared.image.size.width, 1600)
        XCTAssertEqual(prepared.image.size.height, 2100)
        try PageQualityService.inspect(prepared.bytes)
    }
}


@MainActor private final class FakeCalendarWriter: CalendarWriting {
    var allowed = true
    var failure: CalendarSaveFailure?
    var saves = 0
    var pause = false
    var continuation: CheckedContinuation<Bool, Never>?
    func authorize() async throws -> Bool {
        if pause { return await withCheckedContinuation { continuation = $0 } }
        return allowed
    }
    func save(_ request: CalendarEventRequest) throws {
        saves += 1
        if let failure { throw failure }
    }
}
