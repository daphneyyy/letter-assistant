import SwiftUI
import EventKit

@MainActor struct CalendarReviewView: View {
    let proposal: CalendarProposal
    let language: AppLanguage
    let report: (CalendarSaveOutcome) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var selectedDate: Date
    @State private var dateEntered = false
    @State private var durationChoice: Int
    @State private var customDuration: String
    @FocusState private var durationFocused: Bool
    @State private var alert: CalendarAlertChoice
    @State private var customAlertDate: Date
    @State private var zoneID: String
    @State private var reviewedDay: Date
    @State private var midnightNotice = false
    @State private var savedRequest: CalendarEventRequest?
    @StateObject private var saver: CalendarSaveModel

    init(proposal: CalendarProposal, language: AppLanguage, saver: CalendarSaveModel? = nil, report: @escaping (CalendarSaveOutcome) -> Void) {
        _saver = StateObject(wrappedValue: saver ?? CalendarSaveModel())
        self.proposal = proposal; self.language = language; self.report = report
        _durationChoice = State(initialValue: proposal.initialDurationMinutes)
        _customDuration = State(initialValue: String(proposal.initialDurationMinutes))
        _alert = State(initialValue: CalendarAlertChoice.defaultChoice(for: proposal.kind))
        _customAlertDate = State(initialValue: proposal.date ?? Date())
        _title = State(initialValue: proposal.title)
        _selectedDate = State(initialValue: proposal.initialDate())
        _dateEntered = State(initialValue: proposal.kind == .reminder || (proposal.date != nil && (proposal.kind != .appointment || proposal.hasAppointmentTime)))
        _zoneID = State(initialValue: TimeZone.current.identifier)
        _reviewedDay = State(initialValue: Calendar.current.startOfDay(for: Date()))
    }
    var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: zoneID) ?? proposal.timeZone
        return result
    }
    var durationMinutes: Int? {
        durationChoice == 0 ? CalendarDurationPolicy.custom(customDuration) : CalendarDurationPolicy.valid(durationChoice)
    }
    var durationOptions: [Int] { Array(Set(CalendarDurationPolicy.presets + [proposal.initialDurationMinutes])).sorted() }
    var canContinue: Bool { (proposal.kind != .appointment || durationMinutes != nil) && dateEntered && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var body: some View {
        NavigationStack {
            if let savedRequest {
                CalendarConfirmationView(request: savedRequest, kind: proposal.kind, language: language) { dismiss() }
            } else {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(language.text("Calendar event", "日历事项"))
                            .font(.subheadline.weight(.semibold)).foregroundStyle(LetterStyle.accent)
                        Text(language.text("Check the details", "请确认一下"))
                            .font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                        Text(language.text("Check these details before adding to your calendar.", "加入日历前，请核对以下信息。"))
                            .foregroundStyle(LetterStyle.supportingText)
                    }.padding(.vertical, 16)
                }.listRowBackground(Color.clear)
                Section(language.text("Proposed calendar event", "拟添加的日历事项")) {
                    TextField(language.text("Title", "标题"), text: $title, axis: .vertical)
                        .font(.title2.weight(.semibold))
                    if let condition = proposal.condition { Text(condition).font(.headline) }
                    Picker(language.text("Time zone", "时区"), selection: $zoneID) {
                        ForEach(Array(Set(TimeZone.knownTimeZoneIdentifiers + [TimeZone.current.identifier])).sorted(), id: \.self) { Text($0).tag($0) }
                    }.pickerStyle(.menu).accessibilityIdentifier("eventTimeZone")
                    if proposal.kind == .reminder {
                        Text(language.text("No deadline is stated. This is your reminder date, not a letter deadline. Choose a date; no urgency is inferred.", "信中未说明截止日期。这是你选择的提醒日期，不是信件的截止日期。请选择日期；不会推断紧急程度。"))
                        ForEach([1, 3, 7], id: \.self) { days in
                            Button(language.text(days == 1 ? "Tomorrow" : "In \(days) days", days == 1 ? "明天" : "\(days) 天后")) {
                                selectedDate = CalendarDatePolicy.addingDays(days, to: Date(), calendar: calendar)
                                dateEntered = true
                            }.frame(minHeight: 44)
                        }
                    }
                    if proposal.kind == .appointment {
                        Text(proposal.hasAppointmentTime
                            ? language.text("The appointment time is prefilled. Check it against the letter and verify the time zone.", "已填写预约时间。请对照信件核对时间和时区。")
                            : language.text("A single clear appointment time could not be prefilled. Set it from the letter and verify the time zone; the initial time is a placeholder.", "未能填写唯一明确的预约时间。请按信件设置时间并核对时区；初始时间只是占位值。"))
                        if !proposal.hasSourceTimeZone {
                            Text(language.text("Using your phone’s time zone. Verify it against the letter before saving.", "当前使用手机时区。保存前请对照信件核对。"))
                                .font(.callout).foregroundStyle(.secondary)
                        }
                        dateSelection
                        Picker(language.text("Duration", "时长"), selection: $durationChoice) {
                            ForEach(durationOptions, id: \.self) { value in
                                Text(language.text("\(value) minutes", "\(value) 分钟")).tag(value)
                            }
                            Text(language.text("Custom duration", "自定义时长")).tag(0)
                        }.pickerStyle(.navigationLink).accessibilityIdentifier("durationPicker")
                        if durationChoice == 0 {
                            TextField(language.text("Duration in minutes", "时长（分钟）"), text: $customDuration)
                                .keyboardType(.numberPad).focused($durationFocused)
                                .accessibilityIdentifier("customDuration")
                            Text(language.text("Enter 1–1,440 minutes (up to 24 hours).", "请输入 1–1,440 分钟（最多 24 小时）。"))
                                .font(.footnote).foregroundStyle(.secondary)
                            if durationMinutes == nil {
                                Text(language.text("Enter a whole number from 1 to 1,440.", "请输入 1 至 1,440 的整数。"))
                                    .foregroundStyle(.red).accessibilityIdentifier("invalidDuration")
                            }
                        }
                        if let suggested = proposal.suggestedDurationMinutes {
                            Text(language.text("AI estimate: \(suggested) minutes. This is a suggested calendar block; check and adjust it.", "AI 估计：\(suggested) 分钟。这是建议的日历时长，请核对并按需调整。"))
                                .font(.callout).foregroundStyle(.secondary)
                        } else {
                            Text(language.text("No AI duration estimate is available. The default is 30 minutes; choose the time you need.", "暂无 AI 时长估计。默认 30 分钟，请按需要调整。"))
                                .font(.callout).foregroundStyle(.secondary)
                        }
                        if let durationMinutes {
                            LabeledContent(language.text("Ends", "结束时间")) {
                                Text(selectedDate.addingTimeInterval(Double(durationMinutes) * 60), format: Date.FormatStyle(date: .abbreviated, time: .shortened, timeZone: calendar.timeZone))
                            }.accessibilityIdentifier("durationEnd")
                        }
                    } else {
                        dateSelection
                        Text(language.text("All-day event. Choose an alert below.", "全天事项。请在下方选择提醒时间。"))
                    }
                    if (proposal.kind == .appointment ? selectedDate < Date() : calendar.startOfDay(for: selectedDate) < calendar.startOfDay(for: Date())) {
                        Label(language.text("Passed — this date will not be moved automatically.", "日期已过，不会自动顺延。"), systemImage: "clock.badge.exclamationmark")
                    }
                    if calendar.isDateInWeekend(selectedDate), proposal.kind == .reminder {
                        Text(language.text("This date is on a weekend. If contacting an office, check its opening hours or choose another date.", "该日期为周末。如需联系机构，请确认办公时间或另选日期。"))
                    }
                }.listRowBackground(Color.clear)
                Section(language.text("Calendar notes", "日历备注")) {
                    Text(proposal.notes(for: selectedDate, calendar: calendar, language: language)).textSelection(.enabled)
                }.listRowBackground(Color.clear)
                Section(language.text("Alert", "提醒时间")) {
                    Picker(language.text("Notify me", "提醒我"), selection: $alert) {
                        ForEach(CalendarAlertChoice.options(allDay: proposal.kind != .appointment), id: \.self) { choice in
                            Text(choice.label(language)).tag(choice)
                        }
                    }.pickerStyle(.menu).accessibilityIdentifier("alertPicker")
                    if alert == .custom {
                        HStack {
                            Text(language.text("Alert date", "提醒日期"))
                            Spacer(minLength: 12)
                            DatePicker(language.text("Alert date", "提醒日期"), selection: $customAlertDate, displayedComponents: [.date])
                                .labelsHidden().datePickerStyle(.compact)
                                .accessibilityIdentifier("customAlertDate")
                        }
                        HStack {
                            Text(language.text("Alert time", "提醒时间"))
                            Spacer(minLength: 12)
                            DatePicker(language.text("Alert time", "提醒时间"), selection: $customAlertDate, displayedComponents: [.hourAndMinute])
                                .labelsHidden().datePickerStyle(.compact)
                                .accessibilityIdentifier("customAlertTime")
                        }
                        Text(language.text("This exact time stays fixed if you change the event date.", "修改事项日期时，此自定义提醒时间保持不变。"))
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Text(language.text("This is your notification setting, not a time stated in the letter. You can change it here before adding.", "这是你选择的通知时间，并非信件所述时间。添加前可在这里修改。"))
                        .font(.footnote).foregroundStyle(.secondary)
                    if let date = alert.fireDate(start: selectedDate, calendar: calendar, customDate: customAlertDate), date < Date() {
                        Label(language.text("This alert time has passed. Choose another option or review the event date.", "此提醒时间已过。请选择其他选项或核对事项日期。"), systemImage: "clock.badge.exclamationmark")
                    }
                }.listRowBackground(Color.clear)
                Section(language.text("Review the source", "核对信件原文")) {
                    Text(proposal.source).textSelection(.enabled)
                    if let sourceDate = proposal.sourceDate {
                        Text(language.text(proposal.kind == .deadline ? "Deadline in letter: " : "Appointment in letter: ", proposal.kind == .deadline ? "信件截止日期：" : "信件预约时间：") + sourceDate)
                    }
                    if proposal.requiresVerification {
                        Text(language.text("This action or date needs verification. Check the original and enter the date yourself.", "此事项或日期需要核实。请查看原图，并亲自选择日期。"))
                    }
                }.listRowBackground(Color.clear)
                Section {
                    Text(language.text(proposal.kind == .appointment ? "Add directly to your default calendar with the date, duration and alert shown above." : "Add directly to your default calendar with the date and alert shown above.", proposal.kind == .appointment ? "按上方日期、时长和提醒设置，直接添加到默认日历。" : "按上方日期和提醒设置，直接添加到默认日历。"))
                    if let failure = saver.failure {
                        Text(failure.message(language)).foregroundStyle(.red).accessibilityIdentifier("calendarSaveError")
                        if failure == .permissionDenied {
                            Button(language.text("Open Settings", "打开设置")) {
                                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                            }
                        }
                    }
                    if midnightNotice { Text(language.text("The day changed. Check the displayed date, then tap Add again.", "日期已跨天，请查看显示的日期，然后再次点“添加”。")) }
                    Button { addToCalendar() } label: {
                        Label(language.text(saver.isSaving ? "Adding…" : "Add to calendar", saver.isSaving ? "正在添加…" : "添加到日历"), systemImage: "calendar.badge.plus")
                            .font(.headline).frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: 8))
                    .disabled(!canContinue || saver.isSaving || saver.didSave)
                    Button(language.text("Not now", "暂不添加"), role: .cancel) { dismiss() }.frame(minHeight: 44)
                }.listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(LetterStyle.background)
            .listSectionSpacing(28)
            .disabled(saver.isSaving || saver.didSave)
            .interactiveDismissDisabled(saver.isSaving)
            .font(.body)
            .tint(LetterStyle.accent)
            .environment(\.timeZone, calendar.timeZone)
            .environment(\.locale, Locale(identifier: language == .zh ? "zh_CN" : "en_US"))
            .navigationTitle(language.text("Review calendar event", "核对日历事项"))
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: zoneID) { oldValue, newValue in
                if let old = TimeZone(identifier: oldValue), let new = TimeZone(identifier: newValue) {
                    selectedDate = CalendarDatePolicy.changingZone(selectedDate, from: old, to: new)
                    reviewedDay = calendar.startOfDay(for: Date())
                }
            }
            .onChange(of: alert) { oldValue, newValue in
                if newValue == .custom {
                    let defaultChoice = oldValue == .none ? CalendarAlertChoice.defaultChoice(for: proposal.kind) : oldValue
                    customAlertDate = defaultChoice.fireDate(start: selectedDate, calendar: calendar) ?? selectedDate
                }
            }
            .onChange(of: durationChoice) { oldValue, newValue in
                if newValue == 0 && oldValue > 0 { customDuration = String(oldValue) }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(language.text("Done", "完成")) { durationFocused = false }
                }
            }
            }
        }
    }
    private var dateSelection: some View {
        DatePicker(language.text(proposal.kind == .appointment ? "Appointment" : (dateEntered ? "Calendar date" : "Choose a calendar date"), proposal.kind == .appointment ? "预约时间" : (dateEntered ? "日历日期" : "选择日历日期")),
            selection: Binding(get: { selectedDate }, set: { selectedDate = $0; dateEntered = true }),
            displayedComponents: proposal.kind == .appointment ? [.date, .hourAndMinute] : [.date])
            .datePickerStyle(.compact)
            .accessibilityIdentifier("eventDate")
    }

    private func addToCalendar() {
        guard canContinue, !saver.isSaving, !saver.didSave else { return }
        let minutes = durationMinutes ?? 30
        let now = Date()
        if CalendarDatePolicy.reviewExpired(reviewedDay: reviewedDay, now: now, calendar: calendar) {
            reviewedDay = calendar.startOfDay(for: now); midnightNotice = true
            return
        }
        let allDay = proposal.kind != .appointment
        let start = allDay ? calendar.startOfDay(for: selectedDate) : selectedDate
        let request = CalendarEventRequest(title: title, notes: proposal.notes(for: selectedDate, calendar: calendar, language: language), start: start,
            end: CalendarDatePolicy.end(start: start, allDay: allDay, minutes: minutes, calendar: calendar),
            allDay: allDay, timeZone: calendar.timeZone, alert: alert, customAlertDate: customAlertDate)
        Task { @MainActor in
            if await saver.save(request) { savedRequest = request; report(.saved) }
        }
    }
}

private struct CalendarConfirmationView: View {
    let request: CalendarEventRequest
    let kind: CalendarProposal.Kind
    let language: AppLanguage
    let back: () -> Void
    private let background = Color(red: 0.97, green: 0.965, blue: 0.945)
    private let ink = Color(red: 0.12, green: 0.20, blue: 0.19)
    private let accent = Color(red: 0.08, green: 0.36, blue: 0.33)
    private var locale: Locale { Locale(identifier: language == .zh ? "zh_CN" : "en_US") }
    private var dateText: String {
        request.start.formatted(Date.FormatStyle(date: .long, time: .omitted, locale: locale, timeZone: request.timeZone))
    }
    private var eventDetail: String {
        if request.allDay {
            return kind == .deadline ? language.text("All-day deadline", "全天截止事项") : language.text("All-day reminder", "全天提醒事项")
        }
        let format = Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, timeZone: request.timeZone)
        return request.start.formatted(format) + " – " + request.end.formatted(format)
    }
    private var reminderText: String {
        if request.alert == .custom, let date = request.customAlertDate {
            return date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, locale: locale, timeZone: request.timeZone))
        }
        return request.alert.label(language)
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text(language.text("Calendar confirmation", "日历确认"))
                    .font(.title2.bold()).padding(.top, 16)
                VStack(spacing: 24) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 40, weight: .light)).foregroundStyle(accent)
                        .frame(width: 112, height: 112)
                        .background(Color(red: 0.89, green: 0.94, blue: 0.91), in: Circle())
                        .accessibilityHidden(true)
                    Text(language.text("Added to Calendar", "已添加到日历"))
                        .font(.largeTitle.bold()).multilineTextAlignment(.center)
                        .accessibilityIdentifier("calendarConfirmation")
                        .accessibilityAddTraits(.isHeader)
                    Text(language.text("Your event is on your iPhone calendar.", "事项已添加到你的 iPhone 日历。"))
                        .font(.title3).foregroundStyle(ink.opacity(0.75)).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity).padding(.top, 44).padding(.bottom, 12)
                VStack(alignment: .leading, spacing: 20) {
                    Text(request.title).font(.title2.weight(.semibold))
                        .accessibilityIdentifier("savedEventTitle")
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateText).accessibilityIdentifier("savedEventDate")
                        Text(eventDetail)
                    }.font(.title3)
                    Label {
                        Text(language.text("Reminder: ", "提醒：") + reminderText + "\n" + request.timeZone.identifier)
                    } icon: { Image(systemName: "bell") }
                    .font(.body).foregroundStyle(accent).accessibilityIdentifier("savedEventAlert")
                }.padding(28).frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white, in: RoundedRectangle(cornerRadius: 28))
                Text(language.text("You can edit or remove this event in your iPhone Calendar app.", "你可以在 iPhone 日历 App 中修改或删除这个事项。"))
                    .foregroundStyle(ink.opacity(0.75))
                Button(action: back) {
                    Text(language.text("Back to result", "返回解读结果"))
                        .font(.headline).frame(maxWidth: .infinity, minHeight: 60)
                        .foregroundStyle(.white).background(accent, in: RoundedRectangle(cornerRadius: 20))
                }.buttonStyle(.plain).accessibilityIdentifier("backToResult")
            }.padding(24).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }
        .foregroundStyle(ink).background(background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct CalendarEventRequest: Identifiable {
    let id = UUID()
    let title: String
    let notes: String
    let start: Date
    let end: Date
    let allDay: Bool
    let timeZone: TimeZone
    var alert: CalendarAlertChoice = .none
    var customAlertDate: Date? = nil

    func makeEvent(in store: EKEventStore) -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = title; event.notes = notes
        event.startDate = start; event.endDate = end
        // Assigning a non-nil time zone turns an all-day event back into a timed event.
        event.timeZone = allDay ? nil : timeZone
        event.isAllDay = allDay
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        if let fireDate = alert.fireDate(start: start, calendar: calendar, customDate: customAlertDate) {
            event.addAlarm(alert == .custom ? EKAlarm(absoluteDate: fireDate) : EKAlarm(relativeOffset: fireDate.timeIntervalSince(start)))
        }
        return event
    }
}

enum CalendarSaveFailure: Error, Equatable {
    case permissionDenied, unavailable, failed
    func message(_ language: AppLanguage) -> String {
        switch self {
        case .permissionDenied: return language.text("Calendar access was not granted. Allow adding events in Settings, then try again.", "未获得日历添加权限。请在设置中允许添加日历事项后重试。")
        case .unavailable: return language.text("No writable default calendar is available. Set up a calendar account and default calendar in Settings.", "没有可写入的默认日历。请在设置中配置日历账户和默认日历。")
        case .failed: return language.text("Could not confirm the save. Check Calendar before trying again to avoid a duplicate.", "无法确认保存成功。请先查看日历，再重试，以免重复添加。")
        }
    }
}

@MainActor protocol CalendarWriting {
    func authorize() async throws -> Bool
    func save(_ request: CalendarEventRequest) throws
}

@MainActor final class SystemCalendarWriter: CalendarWriting {
    private let store = EKEventStore()
    func authorize() async throws -> Bool {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .writeOnly, .fullAccess: return true
        case .notDetermined: return try await store.requestWriteOnlyAccessToEvents()
        default: return false
        }
    }
    func save(_ request: CalendarEventRequest) throws {
        guard let calendar = store.defaultCalendarForNewEvents, calendar.allowsContentModifications else {
            throw CalendarSaveFailure.unavailable
        }
        let event = request.makeEvent(in: store)
        event.calendar = calendar
        try store.save(event, span: .thisEvent, commit: true)
    }
}

@MainActor final class CalendarSaveModel: ObservableObject {
    @Published private(set) var isSaving = false
    @Published private(set) var didSave = false
    @Published private(set) var failure: CalendarSaveFailure?
    private let writer: any CalendarWriting
    private let defaults: UserDefaults
    init(writer: (any CalendarWriting)? = nil, defaults: UserDefaults = .standard) {
        self.writer = writer ?? SystemCalendarWriter(); self.defaults = defaults
    }
    func save(_ request: CalendarEventRequest) async -> Bool {
        guard !isSaving, !didSave else { return false }
        isSaving = true; failure = nil
        defer { isSaving = false }
        do {
            guard try await writer.authorize() else { failure = .permissionDenied; return false }
            defaults.set(true, forKey: "calendarSavePending")
            defer { defaults.removeObject(forKey: "calendarSavePending") }
            try writer.save(request)
            didSave = true
            return true
        } catch {
            failure = (error as? CalendarSaveFailure) ?? .failed
            return false
        }
    }
}

enum CalendarAlertChoice: Hashable {
    case none, sameDayMorning, previousDayMorning, twoDaysMorning, weekMorning
    case atStart, fiveMinutes, tenMinutes, fifteenMinutes, thirtyMinutes, oneHour, twoHours, oneDay, twoDays, oneWeek, custom

    static func defaultChoice(for kind: CalendarProposal.Kind) -> Self {
        switch kind {
        case .deadline: return .previousDayMorning
        case .appointment: return .oneDay
        case .reminder: return .sameDayMorning
        }
    }

    static func options(allDay: Bool) -> [Self] {
        allDay
            ? [.none, .sameDayMorning, .previousDayMorning, .twoDaysMorning, .weekMorning, .custom]
            : [.none, .atStart, .fiveMinutes, .tenMinutes, .fifteenMinutes, .thirtyMinutes, .oneHour, .twoHours, .oneDay, .twoDays, .oneWeek, .custom]
    }

    func label(_ language: AppLanguage) -> String {
        switch self {
        case .none: return language.text("None", "不提醒")
        case .sameDayMorning: return language.text("On the day at 9 AM", "当天上午 9 点")
        case .previousDayMorning: return language.text("Day before at 9 AM", "前一天上午 9 点")
        case .twoDaysMorning: return language.text("2 days before at 9 AM", "提前 2 天上午 9 点")
        case .weekMorning: return language.text("1 week before at 9 AM", "提前 1 周上午 9 点")
        case .fiveMinutes: return language.text("5 minutes before", "提前 5 分钟")
        case .tenMinutes: return language.text("10 minutes before", "提前 10 分钟")
        case .thirtyMinutes: return language.text("30 minutes before", "提前 30 分钟")
        case .twoHours: return language.text("2 hours before", "提前 2 小时")
        case .oneDay: return language.text("1 day before", "提前 1 天")
        case .twoDays: return language.text("2 days before", "提前 2 天")
        case .oneWeek: return language.text("1 week before", "提前 1 周")
        case .custom: return language.text("Custom date and time", "自定义日期和时间")
        case .atStart: return language.text("At time of event", "事项开始时")
        case .fifteenMinutes: return language.text("15 minutes before", "提前 15 分钟")
        case .oneHour: return language.text("1 hour before", "提前 1 小时")
        }
    }

    func fireDate(start: Date, calendar: Calendar, customDate: Date? = nil) -> Date? {
        switch self {
        case .none: return nil
        case .custom: return customDate
        case .fiveMinutes: return start.addingTimeInterval(-5 * 60)
        case .tenMinutes: return start.addingTimeInterval(-10 * 60)
        case .thirtyMinutes: return start.addingTimeInterval(-30 * 60)
        case .twoHours: return start.addingTimeInterval(-2 * 60 * 60)
        case .oneDay, .twoDays, .oneWeek:
            return calendar.date(byAdding: .day, value: self == .oneDay ? -1 : (self == .twoDays ? -2 : -7), to: start)
        case .atStart: return start
        case .fifteenMinutes: return start.addingTimeInterval(-15 * 60)
        case .oneHour: return start.addingTimeInterval(-60 * 60)
        case .sameDayMorning, .previousDayMorning, .twoDaysMorning, .weekMorning:
            let days = self == .sameDayMorning ? 0 : (self == .previousDayMorning ? -1 : (self == .twoDaysMorning ? -2 : -7))
            let day = CalendarDatePolicy.addingDays(days, to: start, calendar: calendar)
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day)
        }
    }
}
