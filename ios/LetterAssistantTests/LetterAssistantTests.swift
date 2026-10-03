import XCTest
import UIKit
import CoreImage
import EventKit
@testable import LetterAssistant

final class LetterAssistantTests: XCTestCase {
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return result
    }
    func testSystemCalendarEventPreservesAllDayAndTimedAppointment() {
        let start = CalendarDatePolicy.parseDay("2026-03-08", calendar: calendar)!
        let store = EKEventStore()
        let allDay = CalendarEditorRequest(title: "Test deadline", notes: "Fictional", start: start,
            end: CalendarDatePolicy.end(start: start, allDay: true, minutes: 30, calendar: calendar),
            allDay: true, timeZone: calendar.timeZone).makeEvent(in: store)
        XCTAssertTrue(allDay.isAllDay)
        XCTAssertNil(allDay.timeZone)
        XCTAssertEqual(calendar.dateComponents([.year, .month, .day], from: allDay.startDate),
                       calendar.dateComponents([.year, .month, .day], from: start))
        let appointment = CalendarEditorRequest(title: "Test appointment", notes: "Fictional", start: start,
            end: start.addingTimeInterval(1800), allDay: false, timeZone: calendar.timeZone).makeEvent(in: store)
        XCTAssertFalse(appointment.isAllDay)
        XCTAssertEqual(appointment.timeZone, calendar.timeZone)
        XCTAssertEqual(appointment.endDate.timeIntervalSince(appointment.startDate), 1800)
    }
    func testCalendarAlertsAreAttachedAndCanBeDisabled() {
        let start = CalendarDatePolicy.parseDay("2026-10-05", calendar: calendar)!
        let store = EKEventStore()
        for choice in [CalendarAlertChoice.none, .sameDayMorning, .previousDayMorning] {
            let event = CalendarEditorRequest(title: "Test", notes: "", start: start,
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
            let event = CalendarEditorRequest(title: "Test", notes: "", start: start,
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
            let event = CalendarEditorRequest(title: "Test", notes: "", start: start,
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
            let event = CalendarEditorRequest(title: proposal.title, notes: proposal.source, start: start,
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
