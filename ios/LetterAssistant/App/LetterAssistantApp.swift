import SwiftUI

@main struct LetterAssistantApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG && targetEnvironment(simulator)
            if ProcessInfo.processInfo.arguments.contains("--calendar-review-test") {
                CalendarReviewTestHarness()
            } else { CaptureView() }
            #else
            CaptureView()
            #endif
        }
    }
}

#if DEBUG && targetEnvironment(simulator)
private struct CalendarReviewTestHarness: View {
    @State private var outcome: CalendarSaveOutcome?
    @State private var reviewOpen = false
    var body: some View {
        VStack {
            if let outcome { Text(outcome.message(.zh)) }
            Button("Open test review") { reviewOpen = true }
        }.sheet(isPresented: $reviewOpen) {
            let known = ProcessInfo.processInfo.arguments.contains("--known-appointment")
            let appointment = ProcessInfo.processInfo.arguments.contains("--appointment")
            CalendarReviewView(proposal: CalendarProposal(kind: appointment ? .appointment : .reminder,
                title: "虚构测试：联系保险公司", source: "Photo 1: If you want to change plans, contact the office.",
                sourceDate: nil, condition: "如果你希望更换计划", requiresVerification: false,
                date: known ? CalendarProposal.testExample(.appointment, language: .zh).date : nil, reviewedDay: Calendar.current.startOfDay(for: Date()), timeZone: .current, hasAppointmentTime: known,
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
