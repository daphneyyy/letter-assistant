import XCTest
import UIKit
import CoreImage
@testable import LetterAssistant

final class LetterAssistantTests: XCTestCase {
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return result
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
