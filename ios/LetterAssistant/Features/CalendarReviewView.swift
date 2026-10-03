import SwiftUI
import EventKit
import EventKitUI

struct CalendarReviewView: View {
    let proposal: CalendarProposal
    let language: AppLanguage
    let report: (CalendarEditorOutcome) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var selectedDate: Date
    @State private var dateEntered = false
    @State private var confirmed = false
    @State private var minutes = 30
    @State private var zoneID: String
    @State private var reviewedDay: Date
    @State private var midnightNotice = false
    @State private var editor: CalendarEditorRequest?
    @State private var outcome: CalendarEditorOutcome?

    init(proposal: CalendarProposal, language: AppLanguage, report: @escaping (CalendarEditorOutcome) -> Void) {
        self.proposal = proposal; self.language = language; self.report = report
        _title = State(initialValue: proposal.title)
        _selectedDate = State(initialValue: proposal.date ?? Date())
        _zoneID = State(initialValue: proposal.timeZone.identifier)
        _reviewedDay = State(initialValue: proposal.reviewedDay)
    }
    var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: zoneID) ?? proposal.timeZone
        return result
    }
    var needsEntry: Bool { proposal.kind == .appointment || proposal.date == nil || proposal.requiresVerification }
    var canContinue: Bool { confirmed && (!needsEntry || dateEntered) && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var body: some View {
        NavigationStack {
            Form {
                Section(language.text("Review the source", "核对信件原文")) {
                    if let condition = proposal.condition { Text(condition).font(.headline) }
                    Text(proposal.source).textSelection(.enabled)
                    if let sourceDate = proposal.sourceDate {
                        Text(language.text("Letter date: ", "信件所述日期：") + sourceDate)
                    }
                    if proposal.requiresVerification {
                        Text(language.text("This action or date needs verification. Check the original and enter the date yourself.", "此事项或日期需要核实。请查看原图，并亲自选择日期。"))
                    }
                }
                Section(language.text("Proposed calendar event", "拟添加的日历事项")) {
                    TextField(language.text("Title", "标题"), text: $title, axis: .vertical)
                    if proposal.kind == .reminder {
                        Text(language.text("No deadline is stated. This is your reminder date, not a letter deadline. Choose a date; no urgency is inferred.", "信中未说明截止日期。这是你选择的提醒日期，不是信件的截止日期。请选择日期；不会推断紧急程度。"))
                        ForEach([1, 3, 7], id: \.self) { days in
                            Button(language.text(days == 1 ? "Tomorrow" : "In \(days) days", days == 1 ? "明天" : "\(days) 天后")) {
                                selectedDate = CalendarDatePolicy.addingDays(days, to: Date(), calendar: calendar)
                                dateEntered = true; confirmed = false
                            }.frame(minHeight: 44)
                        }
                    }
                    if proposal.kind == .appointment {
                        Text(language.text("Enter the appointment time from the letter and verify its time zone. The extracted date alone does not confirm a time.", "请按信件填写预约时间，并核对时区。提取的日期本身不代表已确认具体时间。"))
                        Picker(language.text("Time zone", "时区"), selection: $zoneID) {
                            ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { Text($0).tag($0) }
                        }
                        DatePicker(language.text("Appointment", "预约时间"), selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                        Stepper(language.text("Duration: \(minutes) minutes", "时长：\(minutes) 分钟"), value: $minutes, in: 5...480, step: 5)
                        Text(language.text("30 minutes is a suggested calendar duration, not a duration stated by the letter. Adjust it if needed.", "默认 30 分钟仅为日历建议时长，并非信件所述时长。可按需调整。"))
                    } else {
                        DatePicker(language.text("Calendar date", "日历日期"), selection: $selectedDate, displayedComponents: .date)
                            .disabled(proposal.kind == .deadline && !proposal.requiresVerification && proposal.date != nil)
                        Text(language.text("All-day event. Set alerts in the system editor.", "全天事项。请在系统编辑器中设置提醒。"))
                    }
                    if needsEntry {
                        Toggle(language.text("I have entered and checked this date/time", "我已填写并核对这个日期／时间"), isOn: $dateEntered)
                    }
                    if (proposal.kind == .appointment ? selectedDate < Date() : calendar.startOfDay(for: selectedDate) < calendar.startOfDay(for: Date())) {
                        Label(language.text("Passed — this date will not be moved automatically.", "日期已过，不会自动顺延。"), systemImage: "clock.badge.exclamationmark")
                    }
                    if calendar.isDateInWeekend(selectedDate), proposal.kind == .reminder {
                        Text(language.text("This date is on a weekend. If contacting an office, check its opening hours or choose another date.", "该日期为周末。如需联系机构，请确认办公时间或另选日期。"))
                    }
                    Text(language.text("Time zone: ", "时区：") + zoneID)
                }
                Section {
                    Toggle(language.text("I confirm the action, conditions, date and time zone", "我确认事项、适用条件、日期和时区"), isOn: $confirmed)
                    Text(language.text("If no calendar is available, cancel and set up a calendar account in iPhone Settings before trying again.", "如果系统没有可用日历，请取消，并先在 iPhone 设置中配置日历账户。"))
                    Text(language.text("The next screen is Apple's editor. Save there to create the event; you can also cancel. Adding again may create a duplicate.", "下一步打开苹果日历编辑器，在那里保存才会创建事项，也可以取消。再次添加可能产生重复事项。"))
                    if midnightNotice { Text(language.text("The day changed. Review the displayed date and confirm again.", "日期已跨天，请重新核对显示的日期并确认。")) }
                    Button(language.text("Confirm and open Calendar", "确认并打开日历")) { openEditor() }
                        .frame(minHeight: 48).disabled(!canContinue || editor != nil)
                    Button(language.text("Not now", "暂不添加"), role: .cancel) { dismiss() }.frame(minHeight: 44)
                }
            }
            .font(.body)
            .environment(\.timeZone, calendar.timeZone)
            .environment(\.locale, Locale(identifier: language == .zh ? "zh_CN" : "en_US"))
            .navigationTitle(language.text("Review calendar event", "核对日历事项"))
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedDate) { _, _ in confirmed = false }
            .onChange(of: zoneID) { _, _ in confirmed = false; dateEntered = false }
            .onChange(of: title) { _, _ in confirmed = false }
            .onChange(of: minutes) { _, _ in confirmed = false }
            .fullScreenCover(item: $editor, onDismiss: {
                UserDefaults.standard.removeObject(forKey: "calendarEditorPending")
                report(outcome ?? .unknown); dismiss()
            }) { request in
                CalendarSystemEditor(request: request) { result in
                    outcome = result; editor = nil
                }.ignoresSafeArea().interactiveDismissDisabled()
            }
        }
    }
    private func openEditor() {
        let now = Date()
        if CalendarDatePolicy.reviewExpired(reviewedDay: reviewedDay, now: now, calendar: calendar) {
            reviewedDay = calendar.startOfDay(for: now); confirmed = false; midnightNotice = true
            return
        }
        let allDay = proposal.kind != .appointment
        let start = allDay ? calendar.startOfDay(for: selectedDate) : selectedDate
        var notes = [proposal.source]
        if let sourceDate = proposal.sourceDate { notes.append(language.text("Date as stated in the letter: ", "信件所述日期：") + sourceDate) }
        if let condition = proposal.condition { notes.append(condition) }
        if proposal.kind == .reminder { notes.append(language.text("User-selected reminder; not a deadline stated by the letter.", "用户选择的提醒日期，并非信中截止日期。")) }
        if needsEntry { notes.append(language.text("Date/time entered and verified by the user.", "日期／时间由用户填写并核对。")) }
        if proposal.kind == .appointment { notes.append(language.text("Calendar duration selected by user; verify against the original letter.", "日历时长由用户选择，请对照原信核实。")) }
        outcome = nil
        UserDefaults.standard.set(true, forKey: "calendarEditorPending")
        editor = CalendarEditorRequest(title: title, notes: notes.joined(separator: "\n\n"), start: start,
            end: CalendarDatePolicy.end(start: start, allDay: allDay, minutes: minutes, calendar: calendar),
            allDay: allDay, timeZone: calendar.timeZone)
    }
}

struct CalendarEditorRequest: Identifiable {
    let id = UUID()
    let title: String
    let notes: String
    let start: Date
    let end: Date
    let allDay: Bool
    let timeZone: TimeZone
}

struct CalendarSystemEditor: UIViewControllerRepresentable {
    let request: CalendarEditorRequest
    let complete: (CalendarEditorOutcome) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(complete: complete) }
    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        let store = context.coordinator.store
        controller.eventStore = store
        let event = EKEvent(eventStore: store)
        event.title = request.title; event.notes = request.notes
        event.startDate = request.start; event.endDate = request.end
        event.isAllDay = request.allDay; event.timeZone = request.timeZone
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}
    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let store = EKEventStore()
        let complete: (CalendarEditorOutcome) -> Void
        private var completed = false
        init(complete: @escaping (CalendarEditorOutcome) -> Void) { self.complete = complete }
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            guard !completed else { return }; completed = true
            switch action {
            case .saved: complete(.saved)
            case .canceled: complete(.canceled)
            default: complete(.unknown)
            }
        }
    }
}
