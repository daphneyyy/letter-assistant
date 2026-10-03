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
    @State private var outcome: CalendarEditorOutcome?
    @State private var reviewOpen = false
    var body: some View {
        VStack {
            if let outcome { Text(outcome.message(.zh)) }
            Button("Open test review") { reviewOpen = true }
        }.sheet(isPresented: $reviewOpen) {
            let appointment = ProcessInfo.processInfo.arguments.contains("--appointment")
            CalendarReviewView(proposal: CalendarProposal(kind: appointment ? .appointment : .reminder,
                title: "虚构测试：联系保险公司", source: "Photo 1: If you want to change plans, contact the office.",
                sourceDate: nil, condition: "如果你希望更换计划", requiresVerification: false,
                date: nil, reviewedDay: Calendar.current.startOfDay(for: Date()), timeZone: .current,
                suggestedDurationMinutes: ProcessInfo.processInfo.arguments.contains("--duration-estimate") ? 50 : nil),
                language: .zh) { outcome = $0 }
        }
    }
}
#endif
