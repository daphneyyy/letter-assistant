import SwiftUI

@main struct LetterAssistantApp: App {
    var body: some Scene {
        WindowGroup {
            #if TEST_BUILD && targetEnvironment(simulator)
            if ProcessInfo.processInfo.arguments.contains("--calendar-review-test") {
                CalendarReviewTestHarness()
            } else { LaunchWelcomeView() }
            #else
            LaunchWelcomeView()
            #endif
        }
    }
}

/// Appears once per app launch, never when returning from a letter or the background.
private struct LaunchWelcomeView: View {
    @State private var showingWelcome = true
    private var language: AppLanguage {
        Locale.preferredLanguages.first?.hasPrefix("zh") == true ? .zh : .en
    }
    var body: some View {
        ZStack {
            CaptureView()
                .accessibilityHidden(showingWelcome)
            if showingWelcome {
                ZStack {
                    LetterStyle.background.ignoresSafeArea()
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Text(language.text("Letter Assistant", "信件助手"))
                                .font(.headline).foregroundStyle(LetterStyle.accent)
                            Text(language.text("One letter. Clear next steps.", "一封信，清楚的下一步。"))
                                .font(.largeTitle.bold()).tracking(-0.6)
                                .accessibilityAddTraits(.isHeader)
                            Text(language.text("Understand your medical or insurance letter in plain language.", "用简单易懂的语言，读懂医疗或保险信件。"))
                                .font(.title3).foregroundStyle(.secondary)
                            Button(language.text("Continue", "继续")) { showingWelcome = false }
                                .font(.headline).frame(minHeight: 48)
                                .tint(LetterStyle.accent)
                        }
                        .padding(32).frame(maxWidth: 600, alignment: .leading)
                        .frame(maxWidth: .infinity)
                    }
                    .defaultScrollAnchor(.center)
                }
                .accessibilityIdentifier("launchWelcome")
                .task {
                    // VoiceOver users control when the welcome finishes.
                    guard !UIAccessibility.isVoiceOverRunning else { return }
                    do { try await Task.sleep(for: .seconds(2)) }
                    catch { return }
                    showingWelcome = false
                }
            }
        }
    }
}

#if TEST_BUILD && targetEnvironment(simulator)
private struct CalendarReviewTestHarness: View {
    @State private var outcome: CalendarSaveOutcome?
    @State private var reviewOpen = false
    var body: some View {
        VStack {
            if let outcome { Text(outcome.message(.zh)) }
            Button("Open test review") { reviewOpen = true }
        }.sheet(isPresented: $reviewOpen) {
            let known = ProcessInfo.processInfo.arguments.contains("--known-appointment")
            let deadline = ProcessInfo.processInfo.arguments.contains("--known-deadline")
            let appointment = ProcessInfo.processInfo.arguments.contains("--appointment")
            CalendarReviewView(proposal: CalendarProposal(kind: appointment ? .appointment : (deadline ? .deadline : .reminder),
                title: "虚构测试：联系保险公司", source: "Photo 1: If you want to change plans, contact the office.",
                sourceDate: nil, condition: "如果你希望更换计划", requiresVerification: false,
                date: deadline ? CalendarProposal.testExample(.deadline, language: .zh).date : (known ? CalendarProposal.testExample(.appointment, language: .zh).date : nil), reviewedDay: Calendar.current.startOfDay(for: Date()), timeZone: .current, hasAppointmentTime: known,
                suggestedDurationMinutes: ProcessInfo.processInfo.arguments.contains("--duration-estimate") ? 50 : nil),
                language: .zh, saver: CalendarSaveModel(writer: CalendarTestWriter())) { outcome = $0 }
        }
    }
}
@MainActor private final class CalendarTestWriter: CalendarWriting {
    func authorize() async throws -> Bool { !ProcessInfo.processInfo.arguments.contains("--save-denied") }
    func save(_ request: CalendarEventRequest) throws {
        if ProcessInfo.processInfo.arguments.contains("--save-unavailable") { throw CalendarSaveFailure.unavailable }
        if ProcessInfo.processInfo.arguments.contains("--save-failed") { throw CalendarSaveFailure.failed }
    }
}
#endif
