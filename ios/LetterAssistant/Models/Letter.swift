import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case en, zh
    // Bundle reflects iOS's per-app language override as well as device preferences.
    static var system: AppLanguage { preferred(for: Bundle.main.preferredLocalizations) }
    static func preferred(for languages: [String]) -> AppLanguage {
        for identifier in languages {
            switch Locale(identifier: identifier).language.languageCode?.identifier {
            case "zh": return .zh
            case "en": return .en
            default: continue
            }
        }
        return .en
    }
    var id: String { rawValue }
    var voice: String { self == .en ? "en-US" : "zh-CN" }
    func text(_ en: String, _ zh: String) -> String { self == .en ? en : zh }
}
struct BilingualText: Codable { let en: String; let zh: String
    func text(_ language: AppLanguage) -> String { language == .en ? en : zh }
}
struct PageValidation: Codable {
    let verdict: String
    let reason: BilingualText
    let validationToken: String?
}
struct SourceReference: Codable, Hashable { let page: Int; let excerpt: String }
struct LetterFact: Codable, Identifiable {
    let id: String; let kind: String; let rawText: String; let value: String?
    let currency: String?; let status: String; let origin: String
    let label: BilingualText; let explanation: BilingualText
    let sourceRefs: [SourceReference]
}
struct LetterAction: Codable, Identifiable {
    let id: String; let descriptionEn: String; let descriptionZh: String
    let actionKind: String; let status: String; let sourceRefs: [SourceReference]
    let requirement: String; let condition: BilingualText?
    let amountFactIds: [String]; let deadlineFactId: String?; let appointmentFactIds: [String]
    var suggestedDurationMinutes: Int? = nil
    var calendarNotes: BilingualText? = nil
    var calendarTitle: BilingualText? = nil
}
struct LetterSummary: Codable {
    let whatThisIs: String; let whatToNote: String; let whatToDo: String; let when: String
    let factIds: [String]; let actionIds: [String]
}
struct LetterSummaries: Codable {
    let en: LetterSummary; let zh: LetterSummary
    func selected(_ language: AppLanguage) -> LetterSummary { language == .en ? en : zh }
}
struct LetterInterpretation: Codable {
    let schemaVersion: Int; let domain: String; let recipient: String?; let organization: String?
    let category: String?; let needsReview: Bool
    let facts: [LetterFact]; let actions: [LetterAction]; let summaries: LetterSummaries
    func heading(_ language: AppLanguage) -> String {
        if domain == "banking" { return language.text("This is a bank or credit-card statement", "这是一份银行或信用卡账单") }
        switch category {
        case "bills" where domain == "billing": return language.text("This is a bill or fee notice", "这是一份账单或费用通知")
        case "bills": return language.text(domain == "medical" ? "This is a medical bill" : "This is a health-insurance bill", domain == "medical" ? "这是一份医疗账单" : "这是一份健康保险账单")
        case "insurance_explanations": return language.text("This is a health-insurance explanation", "这是一份健康保险说明")
        case "appointments": return language.text("This is an appointment notice", "这是一份预约通知")
        case "test_results": return language.text("This is a test result", "这是一份检查结果")
        case "medications": return language.text("This is a medication notice", "这是一份用药通知")
        default: if domain == "billing" { return language.text("This is a billing notice", "这是一份费用通知") }; return language.text(domain == "medical" ? "This is a medical letter" : "This is a health-insurance letter", domain == "medical" ? "这是一份医疗信件" : "这是一份健康保险信件")
        }
    }
}

enum CapturePhase: Equatable {
    case ready, checking, valid, retake, checkFailed, interpreting, interpretFailed, complete
    var busy: Bool { self == .checking || self == .interpreting }
    var canInterpret: Bool { self == .valid || self == .interpretFailed }
}
