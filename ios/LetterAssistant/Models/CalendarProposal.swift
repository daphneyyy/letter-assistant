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
    var eventNotes: String = ""
    var originalDeadline: String? = nil
    var hasDeadlineTime = false
    var isTimedEvent: Bool { kind == .appointment || hasDeadlineTime }
    var hasAppointmentTime = false
    var hasSourceTimeZone = false
    var suggestedDurationMinutes: Int? = nil
    var initialDurationMinutes: Int { CalendarDurationPolicy.valid(suggestedDurationMinutes) ?? 30 }
    func initialDate(now: Date = Date(), calendar: Calendar = .current) -> Date {
        if let date { return isTimedEvent ? date : CalendarDatePolicy.changingZone(date, from: timeZone, to: calendar.timeZone) }
        return kind == .reminder ? CalendarDatePolicy.addingDays(1, to: now, calendar: calendar) : now
    }

    static func make(action: LetterAction, facts: [LetterFact], language: AppLanguage,
                     now: Date = Date(), calendar: Calendar = .current, document: LetterInterpretation? = nil) -> CalendarProposal {
        let deadline = facts.first { $0.id == action.deadlineFactId && $0.kind == "deadline" }
        let linked = facts.filter { action.appointmentFactIds.contains($0.id) }
        let appointments = linked.filter { $0.kind == "appointment_date" }
        let times = linked.filter { $0.kind == "appointment_time" }
        let zones = linked.filter { $0.kind == "appointment_timezone" }
        let fact = deadline ?? appointments.first
        let kind: Kind = deadline != nil ? .deadline : (linked.isEmpty ? .reminder : .appointment)
        var eventCalendar = calendar
        let cutoff = deadline.map { DeadlineClockPolicy.clock(action: action, deadline: $0) }
        let sourceZone = kind == .deadline ? cutoff?.zone : zones.count == 1 && zones[0].status == "confirmed"
            ? zones[0].value.flatMap { TimeZone(identifier: $0) } : nil
        if kind == .appointment || kind == .deadline, let sourceZone { eventCalendar.timeZone = sourceZone }
        var parsed = fact.flatMap { $0.status == "confirmed" ? CalendarDatePolicy.parseDay($0.value, calendar: eventCalendar) : nil }
        var hasTime = false
        if kind == .appointment {
            if appointments.count != 1 { parsed = nil }
            if let day = parsed, times.count == 1, times[0].status == "confirmed",
               zones.isEmpty || sourceZone != nil,
               let combined = CalendarDatePolicy.appointmentDate(day: day, time: times[0].value, calendar: eventCalendar) {
                parsed = combined
                hasTime = true
            }
        }
        if kind == .deadline, let day = parsed, let time = cutoff?.time {
            if let combined = CalendarDatePolicy.appointmentDate(day: day, time: time, calendar: eventCalendar) {
                parsed = combined; hasTime = true
            }
        }
        let balanceRefs = CalendarNoteBuilder.statementBalance(action: action, facts: facts, document: document)?.sourceRefs ?? []
        let allRefs = action.sourceRefs + balanceRefs + (kind == .appointment ? linked.flatMap(\.sourceRefs) : (fact?.sourceRefs ?? []))
        var seen = Set<String>()
        let refs = allRefs.filter { seen.insert("\($0.page):" + CalendarNoteBuilder.normalized($0.excerpt)).inserted }
        return CalendarProposal(kind: kind,
            title: CalendarNoteBuilder.contextualTitle(action: action, facts: facts, language: language, document: document),
            source: refs.map { language.text("Photo \($0.page): ", "第 \($0.page) 张照片：") + $0.excerpt }.joined(separator: "\n"),
            sourceDate: nil, condition: action.condition?.text(language),
            requiresVerification: action.status != "confirmed" || (fact != nil && parsed == nil) || appointments.count > 1 || (kind == .appointment && !hasTime) || (kind == .deadline && hasTime && sourceZone == nil),
            date: parsed, reviewedDay: eventCalendar.startOfDay(for: now), timeZone: eventCalendar.timeZone,
            eventNotes: CalendarNoteBuilder.contextualNotes(action: action, deadline: deadline, language: language, facts: facts, document: document),
            originalDeadline: deadline?.status == "confirmed" ? deadline?.value : nil,
            hasDeadlineTime: kind == .deadline && hasTime,
            hasAppointmentTime: kind == .appointment && hasTime, hasSourceTimeZone: sourceZone != nil,
            suggestedDurationMinutes: kind == .appointment ? CalendarDurationPolicy.valid(action.suggestedDurationMinutes) : nil)
    }
    func notes(for date: Date, calendar: Calendar, language: AppLanguage) -> String {
        let base = eventNotes.isEmpty ? title : eventNotes
        guard let originalDeadline,
              let original = CalendarDatePolicy.parseDay(originalDeadline, calendar: calendar),
              !calendar.isDate(original, inSameDayAs: date) else { return base }
        return base + "\n\n" + language.text("Original payment/action deadline: ", "信件原始付款／办理截止日期：") + originalDeadline
    }

}

enum DeadlineClockPolicy {
    static func clock(action: LetterAction, deadline: LetterFact) -> (time: String?, zone: TimeZone?) {
        if let time = action.deadlineTime {
            return (time, action.deadlineTimezone.flatMap { TimeZone(identifier: $0) })
        }
        // Compatibility with earlier results: read only this action's deadline evidence.
        let text = ([deadline.rawText] + deadline.sourceRefs.map(\.excerpt)).joined(separator: " ")
        guard let regex = try? NSRegularExpression(pattern: #"\b(1[0-2]|0?[1-9])(?::([0-5]\d))?\s*(AM|PM)\b"#, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let hourRange = Range(match.range(at: 1), in: text),
              let periodRange = Range(match.range(at: 3), in: text), let hour = Int(text[hourRange]) else { return (nil, nil) }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        let clocks = Set(matches.compactMap { result -> String? in
            guard let h = Range(result.range(at: 1), in: text), let p = Range(result.range(at: 3), in: text), let hour = Int(text[h]) else { return nil }
            let minute = Range(result.range(at: 2), in: text).flatMap { Int(text[$0]) } ?? 0
            return String(format: "%02d:%02d", hour % 12 + (text[p].uppercased() == "PM" ? 12 : 0), minute)
        })
        guard clocks.count == 1 else { return (nil, nil) }
        let minute = Range(match.range(at: 2), in: text).flatMap { Int(text[$0]) } ?? 0
        let time = String(format: "%02d:%02d", hour % 12 + (text[periodRange].uppercased() == "PM" ? 12 : 0), minute)
        let lower = text.lowercased()
        let zone = lower.contains("eastern time") ? TimeZone(identifier: "America/New_York")
            : lower.range(of: #"\best\b"#, options: .regularExpression) != nil ? TimeZone(identifier: "Etc/GMT+5")
            : lower.range(of: #"\bedt\b"#, options: .regularExpression) != nil ? TimeZone(identifier: "Etc/GMT+4") : nil
        return (time, zone)
    }
}

enum CalendarDatePolicy {
    /// Preserve the displayed calendar day/clock when the user changes scheduling zone.
    static func changingZone(_ date: Date, from oldZone: TimeZone, to newZone: TimeZone) -> Date {
        var old = Calendar(identifier: .gregorian); old.timeZone = oldZone
        var new = old; new.timeZone = newZone
        return new.date(from: old.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)) ?? date
    }

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
    /// Reject missing, invalid, nonexistent and repeated local clock times.
    static func appointmentDate(day: Date, time: String?, calendar: Calendar) -> Date? {
        guard let time, time.range(of: #"^([01]\d|2[0-3]):[0-5]\d$"#, options: .regularExpression) != nil else { return nil }
        let parts = time.split(separator: ":").compactMap { Int($0) }
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = parts[0]; components.minute = parts[1]; components.second = 0
        let before = calendar.startOfDay(for: day).addingTimeInterval(-1)
        guard let first = calendar.nextDate(after: before, matching: components, matchingPolicy: .strict, repeatedTimePolicy: .first),
              let last = calendar.nextDate(after: before, matching: components, matchingPolicy: .strict, repeatedTimePolicy: .last),
              first == last,
              calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: first) == components else { return nil }
        return first
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

enum CalendarSaveOutcome: String {
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
    static func testExample(_ kind: Kind, language: AppLanguage,
                            now: Date = Date(), calendar: Calendar = .current) -> CalendarProposal {
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
            source = language.text("Fictional letter: Your appointment is on \(dateText) at 10:00 AM in your phone's current time zone. Verify the prefilled time below.", "虚构信件：预约在 \(dateText) 上午 10:00，使用手机当前时区。请核对下方已填写的时间。")
        }
        let appointmentDate = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: day)!
        return CalendarProposal(kind: kind, title: title, source: source,
            sourceDate: kind == .reminder ? nil : dateText + (kind == .appointment ? language.text(" at 10:00 AM", " 上午 10:00") : ""),
            condition: kind == .reminder ? language.text("If you want to change plans", "如果你希望更换计划") : nil,
            requiresVerification: false, date: kind == .reminder ? nil : (kind == .appointment ? appointmentDate : day),
            reviewedDay: calendar.startOfDay(for: now), timeZone: calendar.timeZone,
            eventNotes: kind == .appointment
                ? language.text("Clinic appointment. Fictional test event.", "诊所预约。虚构测试事项。")
                : kind == .deadline
                    ? language.text("Submit the insurance form. Fictional test event.", "提交保险表格。虚构测试事项。")
                    : language.text("Contact the insurance office if changing plans. Personal reminder; no deadline stated. Fictional test event.", "如需更换计划，联系保险公司。个人提醒；信中未注明截止日期。虚构测试事项。"),
            hasAppointmentTime: kind == .appointment)
    }
}
#endif


enum CalendarDurationPolicy {
    static let presets = [15, 30, 45, 60, 90, 120, 180, 240]
    static func valid(_ minutes: Int?) -> Int? {
        guard let minutes, (1...1440).contains(minutes) else { return nil }
        return minutes
    }
    static func custom(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        return valid(Int(trimmed))
    }
}


enum CalendarNoteBuilder {
    static func billContext(_ document: LetterInterpretation?, language: AppLanguage) -> String? {
        guard let document, document.category == "bills", ["medical", "insurance", "billing", "banking"].contains(document.domain) else { return nil }
        let type = document.domain == "banking" ? language.text("Bank or credit-card payment", "银行或信用卡还款") : document.domain == "billing" ? language.text("Bill", "账单") : language.text(document.domain == "medical" ? "Medical bill" : "Health-insurance bill", document.domain == "medical" ? "医疗账单" : "健康保险账单")
        let organization = document.organization?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return type + (organization.isEmpty ? "" : " · " + organization)
    }
    static func statementBalance(action: LetterAction, facts: [LetterFact], document: LetterInterpretation?) -> LetterFact? {
        guard document?.domain == "banking", action.actionKind == "payment" else { return nil }
        let amounts = facts.filter { $0.kind == "amount" && $0.status == "confirmed" && $0.value != nil }
        if let id = action.statementBalanceFactId { return amounts.first { $0.id == id } }
        let context = normalized((action.calendarTitle?.en ?? "") + " " + (action.calendarTitle?.zh ?? "") + " " + (document?.summaries.en.whatThisIs ?? "") + " " + (document?.summaries.zh.whatThisIs ?? ""))
        guard ["credit card", "credit-card", "信用卡"].contains(where: { context.contains($0) }) else { return nil }
        let matches = amounts.filter {
            let text = normalized($0.label.en + " " + $0.label.zh + " " + $0.rawText)
            return ["statement balance", "new balance", "账单余额", "本期余额"].contains { text.contains($0) }
                && !text.contains("minimum") && !text.contains("最低")
        }
        return matches.count == 1 ? matches[0] : nil
    }
    static func amountText(_ fact: LetterFact) -> String { [fact.currency, fact.value].compactMap { $0 }.joined(separator: " ") }
    static func contextualTitle(action: LetterAction, facts: [LetterFact], language: AppLanguage, document: LetterInterpretation?) -> String {
        guard action.actionKind == "payment", let context = billContext(document, language: language) else {
            return title(action: action, facts: facts, language: language)
        }
        if let balance = statementBalance(action: action, facts: facts, document: document) {
            return [language.text("Credit-card repayment", "信用卡还款"), document?.organization ?? "", amountText(balance)]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.joined(separator: " · ")
        }
        let amounts = facts.filter { action.amountFactIds.contains($0.id) && $0.status == "confirmed" && $0.kind == "amount" }
            .compactMap { fact in fact.value.map { [fact.currency, $0].compactMap { $0 }.joined(separator: " ") } }
        if ["billing", "banking"].contains(document?.domain ?? "") {
            var heading = title(action: action, facts: facts, language: language)
            let organization = document?.organization?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !organization.isEmpty && !normalized(heading).contains(normalized(organization)) { heading += " · " + organization }
            for amount in amounts where !normalized(heading).contains(normalized(amount)) { heading += " · " + amount }
            return heading
        }
        return language.text("Pay ", "支付：") + context + (amounts.isEmpty ? "" : " · " + amounts.joined(separator: ", "))
    }
    static func contextualNotes(action: LetterAction, deadline: LetterFact?, language: AppLanguage, facts: [LetterFact], document: LetterInterpretation?) -> String {
        if let balance = statementBalance(action: action, facts: facts, document: document) {
            var notes = language.text("Credit-card statement balance: ", "本期信用卡账单余额：") + amountText(balance)
            for fact in facts where action.amountFactIds.contains(fact.id) && fact.kind == "amount" && fact.status == "confirmed" && fact.id != balance.id {
                notes += "\n" + language.text("Source-required minimum payment: ", "信件要求的最低还款额：") + amountText(fact)
            }
            notes += "\n" + language.text("This reminder uses the statement balance; the source minimum is shown separately.", "此还款提醒按账单余额设置，最低还款要求单独列出。")
            if let condition = action.condition { notes += "\n" + language.text("Condition: ", "适用条件：") + condition.text(language) }
            if let deadline { notes += "\n" + language.text("Deadline: ", "截止要求：") + deadline.rawText }
            return notes
        }
        let linked = facts.filter { action.appointmentFactIds.contains($0.id) }
        var notes = make(action: action, deadline: deadline, language: language, facts: linked)
        if action.actionKind == "payment", let context = billContext(document, language: language) {
            let type = context.components(separatedBy: " · ")[0]
            let organization = document?.organization?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !normalized(notes).contains(normalized(type)) || (!organization.isEmpty && !normalized(notes).contains(normalized(organization))) {
                notes = context + "\n\n" + notes
            }
            for fact in facts where action.amountFactIds.contains(fact.id) && fact.kind == "amount" && fact.status == "confirmed" {
                if let value = fact.value, !notes.contains(value) {
                    notes += "\n" + language.text("Payment amount: ", "付款金额：") + [fact.currency, value].compactMap { $0 }.joined(separator: " ")
                }
            }
        }
        return notes
    }
    static func normalized(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ").lowercased()
    }
    static func title(action: LetterAction, facts: [LetterFact], language: AppLanguage) -> String {
        if let title = action.calendarTitle?.text(language).trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty { return title }
        if action.actionKind == "payment" {
            let amounts = facts.filter { action.amountFactIds.contains($0.id) && $0.kind == "amount" && $0.status == "confirmed" }
            let details = amounts.compactMap { fact -> String? in
                guard let value = fact.value else { return nil }
                return [fact.currency, value].compactMap { $0 }.joined(separator: " ")
            }.joined(separator: ", ")
            return language.text("Pay bill", "支付账单") + (details.isEmpty ? "" : " · " + details)
        }
        return language == .en ? action.descriptionEn : action.descriptionZh
    }

    static func make(action: LetterAction, deadline: LetterFact?, language: AppLanguage, facts: [LetterFact] = []) -> String {
        let generated = action.calendarNotes?.text(language).trimmingCharacters(in: .whitespacesAndNewlines)
        let description = language == .en ? action.descriptionEn : action.descriptionZh
        var parts = [generated.flatMap { $0.isEmpty ? nil : $0 } ?? description]
        if let condition = action.condition?.text(language), !condition.isEmpty {
            parts.append(language.text("Condition: ", "适用条件：") + condition)
        } else if action.requirement == "optional" {
            parts.append(language.text("Optional action.", "可选事项。"))
        }
        if let deadline {
            // A date-only deadline is already represented by the calendar day.
            // Keep clock cutoffs/qualifiers and uncertain source text in the note.
            let cutoffPattern = #"(?i)(\b\d{1,2}:\d{2}\b|\b\d{1,2}\s*[ap]\.?m\.?|\b(noon|midnight|business|postmark|received|end of|before)\b|上午|下午|中午|午夜|点|時|时|工作日|寄出|收到|之前)"#
            let needsCutoff = deadline.status != "confirmed" || deadline.value == nil || deadline.rawText.range(of: cutoffPattern, options: .regularExpression) != nil
            if needsCutoff, !deadline.rawText.isEmpty,
               !normalized(parts.joined(separator: " ")).contains(normalized(deadline.rawText)) {
                parts.append(language.text("Deadline details: ", "截止要求：") + deadline.rawText)
            }
        } else if action.appointmentFactIds.isEmpty {
            parts.append(language.text("Personal reminder; no deadline stated.", "个人提醒；信中未注明截止日期。"))
        }
        if action.status != "confirmed" || (deadline != nil && deadline?.status != "confirmed") || facts.contains(where: { $0.status != "confirmed" }) {
            parts.append(language.text("Unconfirmed details in the letter.", "信件中有尚未确认的信息。"))
        }
        return parts.joined(separator: "\n\n")
    }
}
