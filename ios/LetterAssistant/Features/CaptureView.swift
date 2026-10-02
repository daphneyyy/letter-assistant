import SwiftUI

struct CaptureView: View {
    @StateObject private var model = CaptureModel()
    @State private var cameraOpen = false
    @State private var appendPage = false
    @State private var discardPrompt = false
    @State private var finishPrompt = false
    var language: AppLanguage { model.language }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Label(language.text("One letter. Clear next steps.", "一封信，清楚的下一步。"), systemImage: "envelope.open")
                            .font(.title2.weight(.semibold))
                        Spacer(minLength: 0)
                    }
                    HStack(spacing: 12) {
                        languageButton("English", choice: .en)
                        languageButton("中文", choice: .zh)
                    }.disabled(model.phase.busy)
                    Text(language.text("First build • fictional letters only • not saved", "首次构建 · 仅使用虚构信件 · 不保存"))
                        .font(.callout).foregroundStyle(.secondary)
                    if !model.configured {
                        Label(language.text("AI connection setup is still needed for this test build.", "此测试版本仍需设置 AI 连接。"), systemImage: "info.circle")
                            .font(.callout).padding().frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                    if let result = model.result { explanation(result) }
                    else {
                        Text(language.text("Photograph each page of one medical or insurance letter. After every page passes its check, finish taking photos to read the complete letter.", "逐页拍摄同一封医疗或保险信件。每页检查通过后，点击“结束拍摄”解读整封信。"))
                            .font(.system(.title3, design: .default)).fixedSize(horizontal: false, vertical: true)
                    }
                    if !model.pages.isEmpty && model.result == nil {
                        Text(language.text("Page \(model.currentPageIndex + 1) of \(model.pages.count)", "第 \(model.currentPageIndex + 1) 页，共 \(model.pages.count) 页"))
                            .font(.headline)
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(Array(model.pages.enumerated()), id: \.element.id) { index, page in
                                    Button { model.selectPage(index) } label: {
                                        Label(language.text("Page \(index + 1)", "第 \(index + 1) 页"), systemImage: page.isValid ? "checkmark.circle" : "circle")
                                            .padding(8).frame(minHeight: 44)
                                    }.buttonStyle(.bordered)
                                        .accessibilityAddTraits(index == model.currentPageIndex ? .isSelected : [])
                                        .disabled(model.phase.busy)
                                }
                            }
                        }
                    }
                    if model.result != nil {
                        ForEach(Array(model.pages.enumerated()), id: \.element.id) { index, page in
                            Text(language.text("Original page \(index + 1)", "第 \(index + 1) 页原图")).font(.headline)
                            Image(uiImage: page.image).resizable().scaledToFit().frame(maxHeight: 340)
                                .accessibilityLabel(language.text("Original photo, page \(index + 1)", "第 \(index + 1) 页原始照片"))
                        }
                    } else if let image = model.image {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 340)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel(language.text("Original photo of the current letter", "当前信件的原始照片"))
                    }
                    if model.phase.busy {
                        ProgressView(language.text(model.phase == .checking ? "Checking the photo…" : "Reading the letter…", model.phase == .checking ? "正在检查照片…" : "正在解读信件…"))
                            .font(.title3).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if model.result == nil && !model.message.isEmpty {
                        Label(model.message, systemImage: model.phase == .valid ? "checkmark.circle" : "exclamationmark.circle")
                            .font(.title3).fixedSize(horizontal: false, vertical: true)
                    }
                    controls
                }.padding(24)
            }
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
            .sheet(isPresented: $cameraOpen) { CameraSheet(language: language, pageNumber: appendPage ? model.pages.count + 1 : max(1, model.currentPageIndex + 1), receive: { model.accept($0, asNextPage: appendPage) }) }
        }
    }
    @ViewBuilder var controls: some View {
        switch model.phase {
        case .ready, .retake:
            primary(language.text(model.phase == .ready ? "Photograph a letter" : "Retake this page", model.phase == .ready ? "拍摄信件" : "重新拍摄这一页"), icon: "camera.fill") {
                appendPage = false; model.capturePrompt(); cameraOpen = true
            }
            #if targetEnvironment(simulator) && DEBUG
            Button(language.text("Use fictional sample (simulator)", "使用虚构样本（模拟器）")) {
                if let path = Bundle.main.url(forResource: "fictional-bill", withExtension: "jpg"),
                   let image = UIImage(contentsOfFile: path.path) { model.accept(image) }
            }.buttonStyle(.bordered).frame(minHeight: 44)
            #endif
        case .valid:
            primary(language.text("Photograph next page", "拍下一页"), icon: "doc.badge.plus") {
                appendPage = true; model.capturePrompt(); cameraOpen = true
            }.disabled(!model.canAddPage)
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
                .background(language == choice ? Color.accentColor.opacity(0.15) : Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain)
            .accessibilityLabel(choice == .en ? "English" : "中文")
            .accessibilityAddTraits(language == choice ? .isSelected : [])
    }
    func primary(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Label(title, systemImage: icon).font(.title3.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 56).padding(.vertical, 4) }
            .buttonStyle(.borderedProminent)
    }
    @ViewBuilder func explanation(_ result: LetterInterpretation) -> some View {
        if result.domain == "unsupported" {
            section(language.text("Unsupported letter", "暂不支持此类信件"), text: language.text("This first version supports medical and insurance letters.", "首个版本支持医疗和保险信件。"), icon: "info.circle")
        } else {
            let summary = result.summaries.selected(language)
            section(language.text("What this is", "这是什么"), text: summary.whatThisIs, icon: "doc.text")
            section(language.text("Actions and choices", "事项与选择"), text: summary.whatToDo, icon: "list.bullet")
            ForEach(result.actions) { action in
                VStack(alignment: .leading, spacing: 10) {
                    Text(actionLabel(action.requirement)).font(.headline)
                    if let condition = action.condition {
                        Text(condition.text(language)).font(.body)
                    }
                    Text(language == .en ? action.descriptionEn : action.descriptionZh).font(.title3)
                    if action.status == "needs_verification" {
                        Text(language.text("Needs verification", "需要核实")).font(.callout)
                    }
                }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
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
            Label(title, systemImage: icon).font(.headline).accessibilityAddTraits(.isHeader)
            Text(text).font(.title3).fixedSize(horizontal: false, vertical: true)
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
    }
}
