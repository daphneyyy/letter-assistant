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
    @Published private(set) var language = AppLanguage.system
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
    func acceptDocument(_ images: [UIImage]) async {
        guard !phase.busy, result == nil, !images.isEmpty else { return }
        guard pages.count + images.count <= 10 else { report(RelayError(code: "too_many_pages")); return }
        do {
            let additions = try images.map { image -> CapturedPage in
                let prepared = try PageQualityService.prepare(image)
                return CapturedPage(id: UUID(), image: prepared.image, bytes: prepared.bytes)
            }
            let first = pages.count
            let version = generation
            pages.append(contentsOf: additions)
            var firstFailure: (Int, CapturePhase, String, String?)?
            for index in first..<pages.count {
                guard generation == version, !Task.isCancelled else { return }
                currentPageIndex = index; phase = .checkFailed
                validate()
                await work?.value
                guard generation == version, !Task.isCancelled else { return }
                if !pages[index].isValid && firstFailure == nil {
                    firstFailure = (index, phase, message, errorCode)
                }
            }
            if let failure = firstFailure {
                currentPageIndex = failure.0; phase = failure.1; message = failure.2; errorCode = failure.3
            }
        } catch {
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
    func removeCurrentPage() {
        guard !phase.busy, result == nil, pages.indices.contains(currentPageIndex) else { return }
        work?.cancel(); work = nil; generation = UUID()
        pages.remove(at: currentPageIndex)
        guidance.stop()
        if pages.isEmpty { reset() }
        else { selectPage(min(currentPageIndex, pages.count - 1)) }
        announce(language.text("Page deleted. \(pages.count) page(s) remaining.", "已删除页面，剩余 \(pages.count) 页。"))
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
                let verdict = PageValidation(verdict: "valid", reason: BilingualText(en: "Photo checked", zh: "照片已通过检查"), validationToken: "local-readability")
                guard generation == version, !Task.isCancelled else { return }
                pages[index].validation = verdict
                phase = pages[index].isValid ? .valid : .retake
                message = validationMessage(verdict)
                if phase == .retake {
                    guidance.speak(message, language: language); announce(message)
                }
            } catch {
                guard generation == version, !Task.isCancelled else { return }
                if let error = error as? RelayError, error.code == "photo_quality_uncertain" {
                    pages[index].validation = PageValidation(verdict: "uncertain", reason: BilingualText(en: "This photo may be blurry. Retake it, or use it if you can read the text.", zh: "照片可能模糊。你可以重拍，或确认文字可读后仍然使用。"), validationToken: nil)
                    phase = .retake
                    message = validationMessage(pages[index].validation!)
                    guidance.speak(message, language: language); announce(message)
                    return
                }
                if let error = error as? RelayError, error.code == "photo_unreadable" { phase = .retake }
                else { phase = .checkFailed }
                report(error)
            }
        }
    }
    func usePhotoAnyway() {
        guard !phase.busy, result == nil, pages.indices.contains(currentPageIndex),
              validation?.verdict == "uncertain" else { return }
        pages[currentPageIndex].validation = PageValidation(verdict: "valid", reason: BilingualText(en: "Photo accepted by you", zh: "已按你的选择使用照片"), validationToken: "local-user-confirmed")
        errorCode = nil; phase = .valid
        message = validationMessage(pages[currentPageIndex].validation!)
        guidance.stop()
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
        guard language != selected else { return }
        language = selected; guidance.stop()
        if let errorCode { report(RelayError(code: errorCode)) }
        else if result == nil, let validation { message = validationMessage(validation) }
    }
    private func validationMessage(_ verdict: PageValidation) -> String {
        if verdict.verdict == "uncertain" { return verdict.reason.text(language) }
        if verdict.verdict == "valid", verdict.validationToken != nil {
            return ""
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
        guidance.speak(language.text("Hold the phone still and keep the text clear.", "请保持手机稳定，确保文字清晰。"), language: language)
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
        case "too_many_pages": message = language.text("A letter can contain up to 10 pages. Choose a shorter document or delete a page first.", "每封信最多 10 页。请选择页数较少的文件，或先删除页面。")
        case "photo_too_large": message = language.text("This photo is too large to process. Please retake at a lower camera resolution.", "照片过大，无法处理。请降低相机分辨率后重拍。")
        case "validation_expired", "validation_required", "validation_mismatch", "invalid_validation_token": message = language.text("Please check this photo again before interpreting it.", "请先重新检查这张照片，再进行解读。")
        default: message = language.text("We could not complete this step. Your photo is still here. Check the connection and retry.", "未能完成此步骤，照片仍然保留。请检查连接后重试。")
        }
        guidance.speak(message, language: language); announce(message)
    }
    private func announce(_ text: String) { UIAccessibility.post(notification: .announcement, argument: text) }
}
