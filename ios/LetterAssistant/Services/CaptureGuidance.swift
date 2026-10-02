import AVFoundation

@MainActor final class CaptureGuidance {
    private let synthesizer = AVSpeechSynthesizer()
    func speak(_ text: String, language: AppLanguage) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language.voice)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        synthesizer.speak(utterance)
    }
    func stop() { synthesizer.stopSpeaking(at: .immediate) }
}
