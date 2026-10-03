import Foundation

/// Source dates remain separate from user-selected calendar dates.
struct CalendarProposal: Identifiable {
    enum Kind { case deadline, appointment, reminder }
    let id = UUID()
    let kind: Kind
    var title: String
    let source: String
    let sourceDate: String?
    let condition: String?
    let requiresVerification: Bool
    var date: Date?
    let reviewedDay: Date
    let timeZone: TimeZone

    static func make(action: LetterAction, facts: [LetterFact], language: AppLanguage,
                     now: Date = Date(), calendar: Calendar = .current) -> CalendarProposal {
        let deadline = facts.first { $0.id == action.deadlineFactId && $0.kind == "deadline" }
        let appointments = facts.filter { action.appointmentFactIds.contains($0.id) && $0.kind == "appointment_date" }
        let fact = deadline ?? appointments.first
        let kind: Kind = deadline != nil ? .deadline : (appointments.isEmpty ? .reminder : .appointment)
        let parsed = fact.flatMap { $0.status == "confirmed" ? CalendarDatePolicy.parseDay($0.value, calendar: calendar) : nil }
        let prefix = kind == .deadline ? language.text("Deadline: ", "截止：") : kind == .reminder ? language.text("Reminder: ", "提醒：") : ""
        let refs = action.sourceRefs + (fact?.sourceRefs ?? [])
        return CalendarProposal(kind: kind,
            title: prefix + (language == .en ? action.descriptionEn : action.descriptionZh),
            source: refs.map { language.text("Photo \($0.page): ", "第 \($0.page) 张照片：") + $0.excerpt }.joined(separator: "\n"),
            sourceDate: fact?.rawText, condition: action.condition?.text(language),
            requiresVerification: action.status != "confirmed" || (fact != nil && parsed == nil) || appointments.count > 1,
            date: parsed, reviewedDay: calendar.startOfDay(for: now), timeZone: calendar.timeZone)
    }
}

enum CalendarDatePolicy {
    static func parseDay(_ value: String?, calendar: Calendar) -> Date? {
        guard let value, value.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil else { return nil }
        let parts = value.split(separator: "-").compactMap { Int($0) }
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let components = DateComponents(year: parts[0], month: parts[1], day: parts[2])
        guard let date = gregorian.date(from: components),
              gregorian.dateComponents([.year, .month, .day], from: date) == components else { return nil }
        return date
    }
    static func addingDays(_ days: Int, to date: Date, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: date))!
    }
    static func end(start: Date, allDay: Bool, minutes: Int, calendar: Calendar) -> Date {
        allDay ? addingDays(1, to: start, calendar: calendar) : start.addingTimeInterval(Double(minutes) * 60)
    }
    static func reviewExpired(reviewedDay: Date, now: Date, calendar: Calendar) -> Bool {
        !calendar.isDate(reviewedDay, inSameDayAs: now)
    }
}

enum CalendarEditorOutcome: String {
    case saved, canceled, unknown
    func message(_ language: AppLanguage) -> String {
        switch self {
        case .saved: return language.text("Saved to calendar. Manage changes and alerts in Calendar.", "已保存到日历。后续修改和提醒设置请在日历中管理。")
        case .canceled: return language.text("Canceled. Your letter is unchanged.", "已取消，信件内容未改变。")
        case .unknown: return language.text("The result could not be confirmed. Check your calendar before trying again to avoid duplicates.", "无法确认保存结果。请先检查日历，避免重复添加。")
        }
    }
}

#if DEBUG
extension CalendarProposal {
    static func testExample(_ kind: Kind, language: AppLanguage) -> CalendarProposal {
        let calendar = Calendar.current
        let now = Date()
        let day = CalendarDatePolicy.addingDays(3, to: now, calendar: calendar)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .zh ? "zh_CN" : "en_US")
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .long
        let dateText = formatter.string(from: day)
        let title: String
        let source: String
        switch kind {
        case .deadline:
            title = language.text("[TEST] Deadline: submit insurance form", "【测试】截止：提交保险表格")
            source = language.text("Fictional letter: Please submit the insurance form by \(dateText).", "虚构信件：请在 \(dateText) 前提交保险表格。")
        case .reminder:
            title = language.text("[TEST] Reminder: contact insurance office", "【测试】提醒：联系保险公司")
            source = language.text("Fictional letter: If you want to change plans, contact the office. No deadline is stated.", "虚构信件：如希望更换计划，请联系保险公司。未说明截止日期。")
        case .appointment:
            title = language.text("[TEST] Clinic appointment", "【测试】诊所预约")
            source = language.text("Fictional letter: Your appointment is on \(dateText) at 10:00 AM in your phone's current time zone. Enter and verify this time below.", "虚构信件：预约在 \(dateText) 上午 10:00，使用手机当前时区。请在下方填写并核对时间。")
        }
        return CalendarProposal(kind: kind, title: title, source: source,
            sourceDate: kind == .reminder ? nil : dateText,
            condition: kind == .reminder ? language.text("If you want to change plans", "如果你希望更换计划") : nil,
            requiresVerification: false, date: kind == .reminder ? nil : day,
            reviewedDay: calendar.startOfDay(for: now), timeZone: calendar.timeZone)
    }
}
#endif
