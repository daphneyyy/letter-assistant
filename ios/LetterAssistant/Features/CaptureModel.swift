import SwiftUI
import UIKit

struct CapturedPage: Identifiable {
    let id: UUID
    let image: UIImage
    let bytes: Data
    var validation: PageValidation?
    var isValid: Bool { validation?.verdict == "valid" && validation?.validationToken != nil }
}

@MainActor final class CaptureModel: ObservableObject {
    @Published var language = AppLanguage.en
    @Published private(set) var phase = CapturePhase.ready
    @Published private(set) var pages: [CapturedPage] = []
    @Published private(set) var currentPageIndex = 0
    @Published private(set) var result: LetterInterpretation?
    @Published private(set) var message = ""
    var image: UIImage? { pages.indices.contains(currentPageIndex) ? pages[currentPageIndex].image : nil }
    var validation: PageValidation? { pages.indices.contains(currentPageIndex) ? pages[currentPageIndex].validation : nil }
    var canFinishCapture: Bool { !pages.isEmpty && pages.allSatisfy(\.isValid) && !phase.busy }
    var canAddPage: Bool { canFinishCapture && pages.count < 10 && result == nil }
    private var errorCode: String?
    private var captureID = UUID()
    private var generation = UUID()
    private var work: Task<Void, Never>?
    private let api: any LetterAPIClient
    private let inspect: @Sendable (Data) throws -> Void
    init(api: any LetterAPIClient = LetterAPI(configuration: RelayConfiguration.load()),
         inspect: @escaping @Sendable (Data) throws -> Void = { try PageQualityService.inspect($0) }) {
        self.api = api; self.inspect = inspect
    }
    let guidance = CaptureGuidance()
    var configured: Bool { api.isConfigured }
    func accept(_ photo: UIImage, asNextPage: Bool = false) {
        guard !phase.busy else { return }
        if asNextPage && !canAddPage { return }
        do {
            let prepared = try PageQualityService.prepare(photo)
            let pageID = !asNextPage && pages.indices.contains(currentPageIndex) ? pages[currentPageIndex].id : UUID()
            let page = CapturedPage(id: pageID, image: prepared.image, bytes: prepared.bytes)
            if asNextPage || pages.isEmpty {
                pages.append(page); currentPageIndex = pages.count - 1
            } else { pages[currentPageIndex] = page }
            result = nil; message = ""; errorCode = nil
            validate()
        } catch {
            // A failed preparation never replaces an already accepted original.
            if pages.isEmpty { phase = .retake }
            report(error)
        }
    }
    func selectPage(_ index: Int) {
        guard !phase.busy, result == nil, pages.indices.contains(index) else { return }
        currentPageIndex = index; errorCode = nil
        phase = pages[index].isValid ? .valid : (validation == nil ? .checkFailed : .retake)
        message = validation.map(validationMessage) ?? ""
    }
    func validate() {
        guard pages.indices.contains(currentPageIndex), !phase.busy else { return }
        phase = .checking; message = ""; errorCode = nil
        let index = currentPageIndex
        pages[index].validation = nil
        let page = pages[index]
        let version = generation
        announce(language.text("Checking the photo", "正在检查照片"))
        work = Task {
            do {
                let inspect = self.inspect
                try await Task.detached { try inspect(page.bytes) }.value
                try Task.checkCancellation()
                let verdict = try await api.validate(image: page.bytes, captureID: captureID, pageID: page.id)
                guard generation == version, !Task.isCancelled else { return }
                pages[index].validation = verdict
                phase = pages[index].isValid ? .valid : .retake
                message = validationMessage(verdict)
                if phase == .retake {
                    guidance.speak(message, language: language); announce(message)
                }
            } catch {
                guard generation == version, !Task.isCancelled else { return }
                if let error = error as? RelayError, ["photo_unreadable", "photo_cropped"].contains(error.code) { phase = .retake }
                else { phase = .checkFailed }
                report(error)
            }
        }
    }
    func interpret() {
        guard phase.canInterpret, canFinishCapture else { return }
        let inputs = pages.map { LetterPageInput(id: $0.id, image: $0.bytes, token: $0.validation!.validationToken!) }
        phase = .interpreting; message = ""; errorCode = nil
        let version = generation
        announce(language.text("Reading the letter", "正在解读信件"))
        work = Task {
            do {
                let interpretation = try await api.interpret(pages: inputs, captureID: captureID)
                guard generation == version, !Task.isCancelled else { return }
                result = interpretation; phase = .complete
                announce(language.text("Your explanation is ready", "解读已完成"))
            } catch {
                guard generation == version, !Task.isCancelled else { return }
                let code = (error as? RelayError)?.code ?? ""
                if ["validation_expired", "validation_required", "validation_mismatch", "invalid_validation_token"].contains(code) {
                    // Keep every original. Recheck each page rather than losing earlier pages.
                    for index in pages.indices { pages[index].validation = nil }
                    currentPageIndex = 0; phase = .checkFailed
                } else { phase = .interpretFailed }
                report(error)
            }
        }
    }
    func reset() {
        work?.cancel(); work = nil; generation = UUID(); captureID = UUID()
        phase = .ready; pages = []; currentPageIndex = 0; result = nil; message = ""; errorCode = nil
        guidance.stop()
    }
    func changeLanguage(_ selected: AppLanguage) {
        language = selected; guidance.stop()
        if let errorCode { report(RelayError(code: errorCode)) }
        else if result == nil, let validation { message = validationMessage(validation) }
    }
    private func validationMessage(_ verdict: PageValidation) -> String {
        if verdict.verdict == "valid", verdict.validationToken != nil {
            return language.text("Photo checked", "照片已通过检查")
        }
        let reason = verdict.reason.text(language).trimmingCharacters(in: .whitespacesAndNewlines)
        let sentence = reason.components(separatedBy: CharacterSet(charactersIn: "。.!！?？\n")).first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let limit = language == .zh ? 60 : 150
        guard !sentence.isEmpty, sentence.count <= limit else {
            return language.text("We couldn’t confirm the photo is readable. Please retake this page.", "无法确认照片是否清晰，请重拍这一页。")
        }
        return language == .zh ? sentence + "。请重拍这一页。" : sentence + ". Please retake this page."
    }
    func capturePrompt() {
        guidance.speak(language.text("Place the letter on a flat surface. Keep all four edges visible and hold the phone still.", "请把信件放平，拍到纸张的四边，并保持手机稳定。"), language: language)
    }
    private func report(_ error: Error) {
        let code = (error as? RelayError)?.code ?? "connection_failed"
        errorCode = code
        switch code {
        case "local_setup_missing": message = language.text("The local test connection is not set up yet. Your photo has not been interpreted. Ask the developer to complete setup, then retry.", "本地测试连接尚未设置，照片尚未解读。请完成设置后重试。")
        case "provider_not_configured", "missing_api_key", "api_key_missing": message = language.text("AI access has not been configured yet. Keep this photo and retry after setup.", "AI 服务尚未设置。请保留照片，设置后重试。")
        case "provider_auth_failed": message = language.text("The AI access key was rejected. This photo is still here. Update the API key in the local settings and restart the local service before retrying.", "AI 访问密钥无效，照片仍然保留。请在本地设置中更新 API 密钥，重启本地服务后再试。")
        case "provider_rate_limited": message = language.text("The AI service has reached its current request limit. Your photo is still here. Please wait and retry later.", "AI 服务暂时达到请求限额，照片仍然保留。请稍后重试。")
        case "photo_too_small", "photo_unreadable": message = language.text("The text is unclear. Move closer and retake this page.", "文字不清晰，请靠近一些重拍。")
        case "photo_cropped": message = language.text("Text may be cut off. Include all four edges and retake.", "文字可能被裁切，请拍全纸张四边后重拍。")
        case "photo_too_large": message = language.text("This photo is too large to process. Please retake at a lower camera resolution.", "照片过大，无法处理。请降低相机分辨率后重拍。")
        case "validation_expired", "validation_required", "validation_mismatch", "invalid_validation_token": message = language.text("Please check this photo again before interpreting it.", "请先重新检查这张照片，再进行解读。")
        default: message = language.text("We could not complete this step. Your photo is still here. Check the connection and retry.", "未能完成此步骤，照片仍然保留。请检查连接后重试。")
        }
        guidance.speak(message, language: language); announce(message)
    }
    private func announce(_ text: String) { UIAccessibility.post(notification: .announcement, argument: text) }
}
