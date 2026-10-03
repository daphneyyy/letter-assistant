import SwiftUI

struct CaptureView: View {
    @StateObject private var model = CaptureModel()
    @State private var calendarProposal: CalendarProposal?
    @State private var pendingCalendarOutcome: CalendarSaveOutcome?
    @State private var calendarOutcome: CalendarSaveOutcome?
    @State private var calendarTestMenu = false
    @State private var cameraOpen = false
    @State private var appendPage = false
    @State private var discardPrompt = false
    @State private var finishPrompt = false
    var language: AppLanguage { model.language }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    if let result = model.result {
                        explanation(result)
                    } else if model.pages.isEmpty {
                        welcome
                    } else {
                        Text(language.text("Capture every page", "拍摄每一页"))
                            .font(.title2.bold()).accessibilityAddTraits(.isHeader)
                        Text(language.text("Check each photo, then finish to read your letter.", "检查每张照片，完成拍摄后即可解读信件。"))
                            .font(.body).foregroundStyle(.secondary)
                    }
                    if !model.pages.isEmpty && model.result == nil {
                        Text(language.text("Page \(model.currentPageIndex + 1) of \(model.pages.count)", "第 \(model.currentPageIndex + 1) 页，共 \(model.pages.count) 页"))
                            .font(.headline)
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(Array(model.pages.enumerated()), id: \.element.id) { index, page in
                                    Button { model.selectPage(index) } label: {
                                        Label(language.text("Page \(index + 1)", "第 \(index + 1) 页"), systemImage: page.isValid ? "checkmark.circle" : "circle")
                                            .font(.subheadline.weight(.semibold))
                                            .padding(.horizontal, 14).frame(minHeight: 48)
                                            .foregroundStyle(index == model.currentPageIndex ? Color(uiColor: .systemBackground) : LetterStyle.accent)
                                            .background(index == model.currentPageIndex ? LetterStyle.accent : LetterStyle.surface, in: Capsule())
                                    }.buttonStyle(.plain)
                                        .accessibilityAddTraits(index == model.currentPageIndex ? .isSelected : [])
                                        .disabled(model.phase.busy)
                                }
                            }
                        }
                    }
                    if model.result != nil {
                        DisclosureGroup {
                            ForEach(Array(model.pages.enumerated()), id: \.element.id) { index, page in
                                Text(language.text("Original page \(index + 1)", "第 \(index + 1) 页原图")).font(.headline)
                                Image(uiImage: page.image).resizable().scaledToFit().frame(maxHeight: 340)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .accessibilityLabel(language.text("Original photo, page \(index + 1)", "第 \(index + 1) 页原始照片"))
                            }
                        } label: {
                            Label(language.text("Original photos", "信件原图"), systemImage: "photo.on.rectangle")
                                .font(.headline).frame(minHeight: 48)
                        }.padding(20).background(LetterStyle.surface, in: RoundedRectangle(cornerRadius: 22))
                    } else if let image = model.image {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 340)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel(language.text("Original photo of the current letter", "当前信件的原始照片"))
                    }
                    if model.phase.busy {
                        ProgressView(language.text(model.phase == .checking ? "Checking the photo…" : "Reading the letter…", model.phase == .checking ? "正在检查照片…" : "正在解读信件…"))
                            .font(.body).frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20).background(LetterStyle.surface, in: RoundedRectangle(cornerRadius: 18))
                    }
                    if model.result == nil && !model.message.isEmpty {
                        Label(model.message, systemImage: model.phase == .valid ? "checkmark.circle" : "exclamationmark.circle")
                            .font(.body).fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(model.phase == .valid ? LetterStyle.accent : .primary)
                            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                            .background(LetterStyle.surface, in: RoundedRectangle(cornerRadius: 18))
                    }
                    if !model.pages.isEmpty { controls }
                    if model.pages.isEmpty { developmentTools }
                }.padding(24).frame(maxWidth: 680).frame(maxWidth: .infinity)
            }
            .background(LetterStyle.background)
            .tint(LetterStyle.accent)
            .safeAreaInset(edge: .bottom) {
                if model.phase == .complete {
                    primary(language.text("Finish reading", "结束本次阅读"), icon: "checkmark") { finishPrompt = true }
                        .accessibilityHint(language.text("Return to the start screen. This letter has not been saved.", "返回开始页。本次信件尚未保存。"))
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(.regularMaterial)
                }
            }
            .navigationTitle(language.text("Letter Assistant", "信件助手"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if model.phase != .complete && (model.image != nil || model.phase != .ready) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(language.text("Start over", "重新开始")) { discardPrompt = true }.frame(minHeight: 44)
                    }
                }
            }
            .confirmationDialog(language.text("Discard this unsaved letter?", "丢弃这封尚未保存的信件？"), isPresented: $discardPrompt, titleVisibility: .visible) {
                Button(language.text("Discard and start over", "丢弃并重新开始"), role: .destructive) { model.reset() }
                Button(language.text("Keep letter", "保留信件"), role: .cancel) {}
            }
            .alert(language.text("Finish reading?", "结束本次阅读？"), isPresented: $finishPrompt) {
                Button(language.text("Finish and return", "结束并返回"), role: .destructive) { model.reset() }
                Button(language.text("Keep reading", "继续阅读"), role: .cancel) {}
            } message: {
                Text(language.text("This explanation has not been saved. Finishing clears this letter and returns to the start screen.", "本次解读尚未保存。结束后将清除当前信件，并返回开始页。"))
            }
            .confirmationDialog(language.text("Choose a calendar test", "选择日历测试场景"), isPresented: $calendarTestMenu, titleVisibility: .visible) {
                #if DEBUG
                Button(language.text("Deadline", "截止日期")) { calendarProposal = .testExample(.deadline, language: language) }
                Button(language.text("Reminder without a deadline", "无截止日期的提醒")) { calendarProposal = .testExample(.reminder, language: language) }
                Button(language.text("Appointment", "预约")) { calendarProposal = .testExample(.appointment, language: language) }
                #endif
                Button(language.text("Cancel", "取消"), role: .cancel) {}
            }
            .onAppear {
                if calendarProposal == nil && (UserDefaults.standard.bool(forKey: "calendarEditorPending") || UserDefaults.standard.bool(forKey: "calendarSavePending")) {
                    calendarOutcome = .unknown
                    UserDefaults.standard.removeObject(forKey: "calendarEditorPending")
                    UserDefaults.standard.removeObject(forKey: "calendarSavePending")
                }
            }
            .sheet(item: $calendarProposal, onDismiss: {
                calendarOutcome = pendingCalendarOutcome
                pendingCalendarOutcome = nil
            }) { proposal in
                CalendarReviewView(proposal: proposal, language: language) { pendingCalendarOutcome = $0 }
            }
            .alert(language.text("Calendar", "日历"), isPresented: Binding(get: { calendarOutcome != nil }, set: { if !$0 { calendarOutcome = nil } })) {
                Button(language.text("OK", "好")) { calendarOutcome = nil }
            } message: { Text(calendarOutcome?.message(language) ?? "") }
            .fullScreenCover(isPresented: $cameraOpen) { CameraSheet(language: language, pageNumber: appendPage ? model.pages.count + 1 : max(1, model.currentPageIndex + 1), receive: { model.accept($0, asNextPage: appendPage) }) }
        }
    }
    private var header: some View {
        HStack(spacing: 8) {
            languageButton("English", choice: .en)
            languageButton("中文", choice: .zh)
        }
        .padding(4)
        .background(LetterStyle.surface, in: RoundedRectangle(cornerRadius: 16))
        .disabled(model.phase.busy)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 20) {
                welcomeStep("1", title: language.text("Photograph your letter", "拍摄信件"), detail: language.text("One page at a time, with all edges visible.", "逐页拍摄，确保页面边缘完整可见。"))
                welcomeStep("2", title: language.text("Read a clear explanation", "阅读清晰解读"), detail: language.text("Understand the details and your next steps.", "了解重要信息和下一步事项。"))
                welcomeStep("3", title: language.text("Review dates together", "核对相关日期"), detail: language.text("Choose whether to add an event to Calendar.", "自行决定是否添加到日历。"))
            }
            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(LetterStyle.surface, in: RoundedRectangle(cornerRadius: 22))
            controls
            Label(language.text("Demo • fictional letters only • not saved", "演示版 · 仅使用虚构信件 · 不保存"), systemImage: "info.circle")
                .font(.footnote).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func welcomeStep(_ number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number).font(.subheadline.bold()).foregroundStyle(LetterStyle.accent)
                .frame(width: 30, height: 30)
                .background(LetterStyle.accent.opacity(0.10), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }.accessibilityElement(children: .combine)
    }

    @ViewBuilder private var developmentTools: some View {
        if !model.configured {
            Label(language.text("AI connection setup is still needed for this test build.", "此测试版本仍需设置 AI 连接。"), systemImage: "info.circle")
                .font(.callout).foregroundStyle(.secondary)
        }
        #if DEBUG
        DisclosureGroup(language.text("Demo tools", "演示工具")) {
            VStack(alignment: .leading, spacing: 12) {
                Button { calendarTestMenu = true } label: {
                    Label(language.text("Test calendar without AI", "日历测试（无需 AI）"), systemImage: "calendar.badge.plus")
                        .frame(minHeight: 48)
                }.buttonStyle(.bordered).disabled(model.phase.busy)
                Text(language.text("Fictional examples. Adding creates a real calendar event.", "使用虚构样例。点击添加会创建真实日历事项。"))
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding(.top, 12)
        }.font(.subheadline).padding(.vertical, 8)
        #endif
    }

    @ViewBuilder var controls: some View {
        switch model.phase {
        case .ready, .retake:
            primary(language.text(model.phase == .ready ? "Photograph a letter" : "Retake this page", model.phase == .ready ? "拍摄信件" : "重新拍摄这一页"), icon: "camera.fill") {
                appendPage = false; model.capturePrompt(); cameraOpen = true
            }
            if model.validation?.verdict == "uncertain" {
                Button(language.text("Use anyway", "仍然使用")) { model.usePhotoAnyway() }
                    .font(.title3).buttonStyle(.bordered).frame(minHeight: 56)
            }
            #if targetEnvironment(simulator) && DEBUG
            Button(language.text("Use fictional sample (simulator)", "使用虚构样本（模拟器）")) {
                if let path = Bundle.main.url(forResource: "fictional-bill", withExtension: "jpg"),
                   let image = UIImage(contentsOfFile: path.path) { model.accept(image) }
            }.buttonStyle(.bordered).frame(minHeight: 44)
            #endif
        case .valid:
            Button {
                appendPage = true; model.capturePrompt(); cameraOpen = true
            } label: {
                Label(language.text("Photograph next page", "拍下一页"), systemImage: "doc.badge.plus")
                    .font(.headline).frame(maxWidth: .infinity, minHeight: 52)
            }.buttonStyle(.bordered).disabled(!model.canAddPage)
            primary(language.text("Finish taking photos", "结束拍摄"), icon: "checkmark") { model.interpret() }
                .disabled(!model.canFinishCapture)
            Text(language.text("Finish when every page of this letter has been photographed. We’ll interpret all pages together.", "确认这封信的所有页面都已拍摄后，结束拍摄。我们会一起解读所有页面。"))
                .font(.callout).foregroundStyle(.secondary)
            if model.pages.count == 10 {
                Text(language.text("The 10-page limit has been reached.", "已达到每封信 10 页的上限。")).font(.callout)
            }
            #if targetEnvironment(simulator) && DEBUG
            Button(language.text("Add fictional next page (simulator)", "添加虚构下一页（模拟器）")) {
                if let path = Bundle.main.url(forResource: "fictional-bill-page2", withExtension: "jpg"),
                   let image = UIImage(contentsOfFile: path.path) { model.accept(image, asNextPage: true) }
            }.buttonStyle(.bordered).frame(minHeight: 44).disabled(!model.canAddPage)
            #endif
            Button(language.text("Retake this page", "重新拍摄这一页")) { appendPage = false; model.capturePrompt(); cameraOpen = true }.buttonStyle(.bordered).frame(minHeight: 44)
        case .checkFailed:
            primary(language.text("Retry photo check", "重试照片检查"), icon: "arrow.clockwise") { model.validate() }
        case .interpretFailed:
            primary(language.text("Retry interpretation", "重试解读"), icon: "arrow.clockwise") { model.interpret() }
        case .complete:
            Button { discardPrompt = true } label: {
                Label(language.text("Photograph another letter", "拍摄另一封信"), systemImage: "camera")
                    .font(.title3).frame(maxWidth: .infinity, minHeight: 56)
            }.buttonStyle(.bordered)
        case .checking, .interpreting: EmptyView()
        }
    }
    func languageButton(_ title: String, choice: AppLanguage) -> some View {
        Button { model.changeLanguage(choice) } label: {
            Text(title).font(.headline).frame(maxWidth: .infinity, minHeight: 48)
                .foregroundStyle(language == choice ? Color(uiColor: .systemBackground) : .primary)
                .background(language == choice ? LetterStyle.accent : Color.clear, in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
            .accessibilityLabel(choice == .en ? "English" : "中文")
            .accessibilityAddTraits(language == choice ? .isSelected : [])
    }
    func primary(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Label(title, systemImage: icon).font(.title3.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 56).padding(.vertical, 4) }
            .buttonStyle(.borderedProminent).tint(LetterStyle.button).controlSize(.large)
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    @ViewBuilder func explanation(_ result: LetterInterpretation) -> some View {
        if result.domain == "unsupported" {
            section(language.text("Unsupported letter", "暂不支持此类信件"), text: language.text("This first version supports medical and insurance letters.", "首个版本支持医疗和保险信件。"), icon: "info.circle")
        } else {
            let summary = result.summaries.selected(language)
            section(language.text("What this letter says", "这封信主要说什么"), text: summary.whatThisIs, icon: "doc.text")
            section(language.text("What to pay attention to", "你需要留意什么"), text: summary.whatToNote, icon: "eye")
            section(language.text("Actions and choices", "事项与选择"), text: summary.whatToDo, icon: "list.bullet")
            ForEach(result.actions) { action in
                VStack(alignment: .leading, spacing: 10) {
                    Text(actionLabel(action.requirement)).font(.headline)
                    if let condition = action.condition {
                        Text(condition.text(language)).font(.body)
                    }
                    Text(language == .en ? action.descriptionEn : action.descriptionZh).font(.title3)
                    Button {
                        calendarProposal = CalendarProposal.make(action: action, facts: result.facts, language: language, document: result)
                    } label: {
                        Label(language.text("Review calendar event", "查看并添加到日历"), systemImage: "calendar.badge.plus")
                            .frame(minHeight: 48)
                    }.buttonStyle(.bordered)
                    if action.status == "needs_verification" {
                        Text(language.text("Needs verification", "需要核实")).font(.callout)
                    }
                }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(LetterStyle.surface, in: RoundedRectangle(cornerRadius: 22))
            }
            section(language.text("Relevant timing", "相关时间"), text: summary.when, icon: "clock")
            if !result.facts.isEmpty {
                DisclosureGroup {
                    ForEach(result.facts) { fact in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(fact.label.text(language)).font(.headline)
                            Text(fact.explanation.text(language)).font(.title3)
                            if fact.status == "confirmed", let value = fact.value {
                                Text([fact.kind == "amount" ? fact.currency : nil, value].compactMap { $0 }.joined(separator: " "))
                                    .font(.body.weight(.semibold))
                            } else {
                                Text(language.text(fact.status == "not_specified" ? "Not specified in the letter" : "Needs verification", fact.status == "not_specified" ? "信中未说明" : "需要核实")).font(.body)
                            }
                            ForEach(fact.sourceRefs, id: \.self) { source in
                                Text(language.text("From photo \(source.page): ", "第 \(source.page) 张照片原文：") + source.excerpt)
                                    .font(.body).foregroundStyle(.secondary)
                            }
                        }.padding(.vertical, 12).frame(maxWidth: .infinity, alignment: .leading)
                    }
                } label: {
                    Text(language.text("Key details and source text", "查看关键细节与原文")).font(.headline).frame(minHeight: 48)
                }
            }
        }
        Text(language.text("Compare important details with the original photo. This explanation has not been saved.", "请对照原图核实重要信息。本次解读尚未保存。"))
            .font(.callout).foregroundStyle(.secondary)
    }
    func actionLabel(_ requirement: String) -> String {
        switch requirement {
        case "required": return language.text("Explicitly requested", "信中明确要求")
        case "optional": return language.text("An option in the letter", "信中提供的选择")
        default: return language.text("Applies if the condition is met", "符合条件时适用")
        }
    }
    func section(_ title: String, text: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon).font(.headline).foregroundStyle(LetterStyle.accent).accessibilityAddTraits(.isHeader)
            Text(text).font(.title3).fixedSize(horizontal: false, vertical: true)
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(LetterStyle.surface, in: RoundedRectangle(cornerRadius: 22))
    }
}

// Adaptive colors keep the same hierarchy in light and dark appearances.
enum LetterStyle {
    static let button = Color(red: 0.08, green: 0.37, blue: 0.33)
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.30, green: 0.76, blue: 0.68, alpha: 1)
            : UIColor(red: 0.08, green: 0.37, blue: 0.33, alpha: 1)
    })
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
}
