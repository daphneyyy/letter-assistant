import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case en, zh
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
}
struct LetterSummary: Codable {
    let whatThisIs: String; let whatToDo: String; let when: String
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
}

enum CapturePhase: Equatable {
    case ready, checking, valid, retake, checkFailed, interpreting, interpretFailed, complete
    var busy: Bool { self == .checking || self == .interpreting }
    var canInterpret: Bool { self == .valid || self == .interpretFailed }
}
