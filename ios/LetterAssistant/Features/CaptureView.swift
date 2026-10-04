import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct CaptureView: View {
    @ObservedObject var model: CaptureModel
    @State private var calendarProposal: CalendarProposal?
    @State private var pendingCalendarOutcome: CalendarSaveOutcome?
    @State private var calendarOutcome: CalendarSaveOutcome?
    @State private var calendarTestMenu = false
    @State private var cameraOpen = false
    @State private var photoZoomOpen = false
    @State private var fileImportOpen = false
    @State private var fileImportError: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var importingPhoto = false
    @State private var photoImportFailed = false
    @State private var appendPage = false
    @State private var discardPrompt = false
    @State private var finishPrompt = false
    @State private var languageSettingsPrompt = false
    @State private var deletePagePrompt = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.openURL) private var openURL
    var language: AppLanguage { model.language }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let result = model.result {
                        explanation(result)
                    } else if model.pages.isEmpty {
                        welcome
                    }
                    if !model.pages.isEmpty && model.result == nil {
                        photoReviewCard
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
                        }.padding(.vertical, 16)
                    }
                    if importingPhoto {
                        ProgressView(language.text("Loading photo…", "正在载入照片…")).font(.body)
                    }
                    if model.phase.busy {
                        ProgressView(language.text(model.phase == .checking ? "Checking the photo…" : "Reading the letter…", model.phase == .checking ? "正在检查照片…" : "正在解读信件…"))
                            .font(.body).frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20).background(LetterStyle.surface, in: RoundedRectangle(cornerRadius: 8))
                    }
                    if model.result == nil && !model.message.isEmpty {
                        Label(model.message, systemImage: "exclamationmark.circle")
                            .font(.body).fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(.primary)
                            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                            .background(LetterStyle.surface, in: RoundedRectangle(cornerRadius: 8))
                    }
                    if !model.pages.isEmpty { controls }
                    if model.pages.isEmpty { developmentTools }
                }.padding(24).frame(maxWidth: 680).frame(maxWidth: .infinity)
            }
            .disabled(importingPhoto)
            .background(LetterStyle.background.ignoresSafeArea())
            .foregroundStyle(LetterStyle.ink)
            .tint(LetterStyle.accent)
            .safeAreaInset(edge: .bottom) {
                if model.phase == .complete {
                    primary(language.text("Finish reading", "结束本次阅读"), icon: "checkmark") { finishPrompt = true }
                        .accessibilityHint(language.text("Return to the start screen. This letter has not been saved.", "返回开始页。本次信件尚未保存。"))
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(LetterStyle.background)
                }
            }
            .navigationTitle(language.text("Letter Assistant", "信件助手"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        languageSettingsPrompt = true
                    } label: {
                        Image(systemName: "globe").font(.title3).frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(language.text("Language settings", "语言设置"))
                    .accessibilityHint(language.text("Choose this app's language in iPhone Settings.", "在 iPhone 系统设置中选择本 App 的语言。"))
                    .accessibilityIdentifier("languageSettings")
                    .disabled(model.phase.busy || importingPhoto)
                }
                if model.phase != .complete && (model.image != nil || model.phase != .ready) {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(language.text("Start over", "重新开始")) { discardPrompt = true }.frame(minHeight: 44).disabled(importingPhoto)
                    }
                }
            }
            .alert(language.text("Open language settings?", "打开语言设置？"), isPresented: $languageSettingsPrompt) {
                Button(language.text("Open Settings", "打开设置")) { openLanguageSettings() }
                Button(language.text("Keep reading", "继续阅读"), role: .cancel) {}
            } message: {
                Text(language.text("In Settings, go to Apps → this app → Language / Preferred Language. Your choice overrides the phone's language for this app.", "在系统设置中进入「App → 本 App → 语言／首选语言」。这里的选择会覆盖手机语言，仅应用于本 App。")
                     + (model.pages.isEmpty ? "" : "\n\n" + language.text("Changing the app language restarts the app and clears this unsaved letter. Finish reading first if you want to keep it open.", "更改 App 语言会重启 App，并清除当前尚未保存的信件。如需保留当前阅读，请先读完再切换语言。")))
            }
            .alert(language.text("Delete page \(model.currentPageIndex + 1)?", "删除第 \(model.currentPageIndex + 1) 页？"), isPresented: $deletePagePrompt) {
                Button(language.text("Delete page", "删除此页"), role: .destructive) { model.removeCurrentPage() }
                Button(language.text("Keep page", "保留此页"), role: .cancel) {}
            } message: {
                Text(language.text("The other pages will stay in their current order.", "其他页面会保留，并保持原来的顺序。"))
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
                #if TEST_BUILD
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
                calendarOutcome = pendingCalendarOutcome == .saved ? nil : pendingCalendarOutcome
                pendingCalendarOutcome = nil
            }) { proposal in
                CalendarReviewView(proposal: proposal, language: language) { pendingCalendarOutcome = $0 }
            }
            .alert(language.text("Calendar", "日历"), isPresented: Binding(get: { calendarOutcome != nil }, set: { if !$0 { calendarOutcome = nil } })) {
                Button(language.text("OK", "好")) { calendarOutcome = nil }
            } message: { Text(calendarOutcome?.message(language) ?? "") }
            .fileImporter(isPresented: $fileImportOpen, allowedContentTypes: [.pdf]) { result in
                switch result {
                case .success(let url):
                    Task { @MainActor in
                        importingPhoto = true
                        defer { importingPhoto = false }
                        do {
                            let images = try LetterFileImport.images(from: url, maximumPages: 10 - model.pages.count)
                            await model.acceptDocument(images)
                        } catch {
                            let code = (error as? RelayError)?.code
                            fileImportError = code == "too_many_pages"
                                ? language.text("A letter can contain up to 10 pages.", "每封信最多 10 页。")
                                : (code == "file_too_large"
                                   ? language.text("Choose a file smaller than 30 MB.", "请选择小于 30 MB 的文件。")
                                   : language.text("Could not read this file. Choose an unlocked PDF or a photo. Existing pages are still here.", "无法读取文件。请选择未加密的 PDF 或照片。已有页面仍然保留。"))
                        }
                    }
                case .failure(let error):
                    if (error as NSError).code != NSUserCancelledError {
                        fileImportError = language.text("Could not open this file. Please try again.", "无法打开文件，请重试。")
                    }
                }
            }
            .alert(language.text("File import", "上传文件"), isPresented: Binding(get: { fileImportError != nil }, set: { if !$0 { fileImportError = nil } })) {
                Button(language.text("OK", "好"), role: .cancel) { fileImportError = nil }
            } message: { Text(fileImportError ?? "") }
            .task(id: selectedPhoto) {
                guard let item = selectedPhoto else { return }
                let asNextPage = model.phase == .valid
                importingPhoto = true
                defer { importingPhoto = false; selectedPhoto = nil }
                do {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let photo = UIImage(data: data) else { photoImportFailed = true; return }
                    try Task.checkCancellation()
                    model.accept(photo, asNextPage: asNextPage)
                } catch is CancellationError {
                    // Dismissing or replacing a selection leaves the existing letter intact.
                } catch { photoImportFailed = true }
            }
            .alert(language.text("Could not load photo", "无法载入照片"), isPresented: $photoImportFailed) {
                Button(language.text("OK", "好"), role: .cancel) {}
            } message: {
                Text(language.text("Choose the photo again or photograph the letter. Your existing pages are still here.", "请重新选择照片，或拍摄信件。已有页面仍然保留。"))
            }
            .fullScreenCover(isPresented: $cameraOpen) { CameraSheet(language: language, pageNumber: appendPage ? model.pages.count + 1 : max(1, model.currentPageIndex + 1), receive: { model.accept($0, asNextPage: appendPage) }) }
            .fullScreenCover(isPresented: $photoZoomOpen) {
                if !model.pages.isEmpty {
                    NavigationStack {
                        TabView(selection: Binding(get: { model.currentPageIndex }, set: { model.selectPage($0) })) {
                            ForEach(Array(model.pages.enumerated()), id: \.element.id) { index, page in
                                ZoomablePhotoView(image: page.image).tag(index)
                                    .accessibilityHidden(index != model.currentPageIndex)
                            }
                        }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .background(LetterStyle.background.ignoresSafeArea())
                            .safeAreaInset(edge: .bottom) {
                                Text(language.text("Swipe to change photos · Pinch or double-tap to zoom", "左右滑动切换照片 · 双指缩放或双击放大"))
                                    .font(.callout).foregroundStyle(LetterStyle.supportingText)
                                    .padding().frame(maxWidth: .infinity).background(LetterStyle.background)
                            }
                            .navigationTitle(language.text("Photo \(model.currentPageIndex + 1) of \(model.pages.count)", "第 \(model.currentPageIndex + 1) 张，共 \(model.pages.count) 张"))
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button(language.text("Done", "完成")) { photoZoomOpen = false }
                                        .accessibilityIdentifier("closePhotoZoom")
                                }
                            }
                    }.tint(LetterStyle.accent).accessibilityIdentifier("photoZoomViewer")
                }
            }
        }
    }
    private func openLanguageSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
    private var photoReviewCard: some View {
        VStack(spacing: 0) {
            pageNavigation.padding(12).background(LetterStyle.background)
            TabView(selection: Binding(get: { model.currentPageIndex }, set: { model.selectPage($0) })) {
                ForEach(Array(model.pages.enumerated()), id: \.element.id) { index, page in
                    Button { photoZoomOpen = true } label: {
                        Image(uiImage: page.image).resizable().scaledToFit().padding(16)
                    }.buttonStyle(.plain).tag(index)
                        .accessibilityIdentifier(index == model.currentPageIndex ? "reviewPhotoPreview" : "reviewPhotoPreview-\(index)")
                        .accessibilityLabel(language.text("Original photo, page \(index + 1)", "第 \(index + 1) 页原始照片"))
                        .accessibilityHint(language.text("Tap to zoom. Swipe left or right to change pages.", "点击放大。左右滑动切换页面。"))
                        .accessibilityHidden(index != model.currentPageIndex)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never)).frame(height: 420)
            .disabled(model.phase.busy || importingPhoto)
        }
        .background(LetterStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(LetterStyle.rule, lineWidth: 1) }
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private func addPageCell(_ title: String, icon: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.title2).foregroundStyle(LetterStyle.accent)
                .frame(width: 56, height: 56).background(LetterStyle.softMint, in: Circle())
            Text(title).font(.headline).foregroundStyle(LetterStyle.accent)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }.padding(12).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LetterStyle.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(LetterStyle.rule, lineWidth: 1) }
    }

    private var pageNavigation: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button { appendPage = false; model.capturePrompt(); cameraOpen = true } label: {
                    Text(language.text("Retake", "重拍")).font(.callout.weight(.semibold))
                        .foregroundStyle(LetterStyle.accent).frame(minWidth: 54, minHeight: 44)
                }.accessibilityIdentifier("retakePage")
                Menu {
                    ForEach(Array(model.pages.enumerated()), id: \.element.id) { index, page in
                        Button { model.selectPage(index) } label: {
                            Label(language.text("Page \(index + 1)", "第 \(index + 1) 页"), systemImage: index == model.currentPageIndex ? "checkmark" : (page.isValid ? "checkmark.circle" : "exclamationmark.circle"))
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(language.text("Page \(model.currentPageIndex + 1) of \(model.pages.count)", "第 \(model.currentPageIndex + 1) 页，共 \(model.pages.count) 页"))
                            .font(.headline).multilineTextAlignment(.center)
                        Image(systemName: "chevron.down").font(.caption.bold())
                    }.frame(maxWidth: .infinity, minHeight: 48)
                }
                .accessibilityIdentifier("pageSelector")
                .accessibilityHint(language.text("Choose a page to view", "选择要查看的页面"))
                Button(role: .destructive) { deletePagePrompt = true } label: {
                    Text(language.text("Delete", "删除")).font(.callout.weight(.semibold))
                        .foregroundStyle(.red).frame(minWidth: 54, minHeight: 44)
                }.accessibilityIdentifier("deletePage")
            }
            .foregroundStyle(LetterStyle.ink)
            .buttonStyle(.plain)
        }.disabled(model.phase.busy || importingPhoto)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text(language.text("Ready to analyze", "准备开始分析"))
                    .font(.largeTitle.bold()).foregroundStyle(LetterStyle.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(language.text("Choose how you want to start. Take a photo, upload a saved image, or add a PDF.", "选择开始方式：拍摄照片、上传已有图片，或添加 PDF。"))
                    .font(.title3).foregroundStyle(LetterStyle.supportingText)
                    .fixedSize(horizontal: false, vertical: true)
            }.frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 16) {
                Label {
                    Text(language.text("Start with your letter", "从您的信件开始"))
                } icon: {
                    LetterScanIcon().stroke(LetterStyle.accent, style: StrokeStyle(lineWidth: 1, lineCap: .round))
                        .frame(width: 25, height: 25).accessibilityHidden(true)
                }
                    .font(.title3.weight(.semibold)).foregroundStyle(LetterStyle.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button { appendPage = false; model.capturePrompt(); cameraOpen = true } label: {
                    Label(language.text("Take a New Photo", "拍摄新照片"), systemImage: "camera")
                        .font(.title3.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 60)
                        .padding(.horizontal, 12).foregroundStyle(.white)
                        .background(LetterStyle.button, in: RoundedRectangle(cornerRadius: 18))
                }.buttonStyle(.plain).accessibilityIdentifier("takePhoto")
                PhotosPicker(selection: $selectedPhoto, matching: .images, preferredItemEncoding: .compatible) {
                    welcomeUploadLabel(language.text("Upload Existing Photo", "上传已有照片"))
                }.buttonStyle(.plain).accessibilityIdentifier("uploadExistingPhoto")
                Button { fileImportOpen = true } label: {
                    welcomeUploadLabel(language.text("Upload Document (PDF)", "上传文档（PDF）"))
                }.buttonStyle(.plain).accessibilityIdentifier("uploadFile")
                Text(language.text("JPG, PNG, or PDF · Add multiple pages", "支持 JPG、PNG 或 PDF · 可添加多页"))
                    .font(.callout).foregroundStyle(LetterStyle.supportingText)
                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)
            }
            .padding(22).background(LetterStyle.softMint, in: RoundedRectangle(cornerRadius: 26))
            Label(language.text("Your letter is sent to AI only when you tap Start analysis. Photos and results stay only in this session.", "点击“开始分析”后才会发送文件给 AI。照片和结果仅临时使用。"), systemImage: "checkmark.shield")
                .font(.callout).foregroundStyle(LetterStyle.supportingText)
                .fixedSize(horizontal: false, vertical: true)
            #if TEST_BUILD
            Button(language.text("Use test photo", "使用测试照片")) {
                if let file = Bundle.main.url(forResource: "fictional-bill", withExtension: "jpg"),
                   let image = UIImage(contentsOfFile: file.path) { model.accept(image) }
            }.frame(minHeight: 44)
            #endif
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 20) {
                    welcomeStep("1", title: language.text("Photograph your letter", "拍摄信件"), detail: language.text("One page at a time, with all edges visible.", "逐页拍摄，确保页面边缘完整可见。"))
                    welcomeStep("2", title: language.text("Read a clear explanation", "阅读清晰解读"), detail: language.text("Understand the details and your next steps.", "了解重要信息和下一步事项。"))
                    welcomeStep("3", title: language.text("Review dates together", "核对相关日期"), detail: language.text("Choose whether to add an event to Calendar.", "自行决定是否添加到日历。"))
                }.padding(.top, 12)
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "questionmark")
                        .font(.headline).foregroundStyle(LetterStyle.accent)
                        .frame(width: 44, height: 44)
                        .background(LetterStyle.softMint, in: RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(language.text("How to use", "如何使用")).font(.headline)
                        Text(language.text("Photo · Explanation · Calendar", "拍照 · 解读 · 日历"))
                            .font(.subheadline).foregroundStyle(LetterStyle.supportingText)
                    }
                }.frame(minHeight: 52)
            }
            .accessibilityIdentifier("howToUse")
            .padding(.vertical, 16).frame(maxWidth: .infinity, alignment: .leading)
            #if TEST_BUILD
            Label(language.text("Test version • fictional letters • not saved", "测试版 · 虚构信件 · 不保存"), systemImage: "info.circle")
                .font(.footnote).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            #endif
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
            Label(language.text("AI connection is not configured.", "尚未配置 AI 连接。"), systemImage: "info.circle")
                .font(.callout).foregroundStyle(.secondary)
        }
        #if TEST_BUILD
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
            primary(language.text(model.phase == .ready ? "Photograph a letter" : "Retake this page", model.phase == .ready ? "拍摄信件" : "重新拍摄这一页"), icon: "camera", showsArrow: model.phase == .ready) {
                appendPage = false; model.capturePrompt(); cameraOpen = true
            }
            photoLibraryButton
            if model.validation?.verdict == "uncertain" {
                Button(language.text("Use anyway", "仍然使用")) { model.usePhotoAnyway() }
                    .font(.title3).buttonStyle(.bordered).frame(minHeight: 56)
            }
            #if TEST_BUILD
            Button {
                if let path = Bundle.main.url(forResource: "fictional-bill", withExtension: "jpg"),
                   let image = UIImage(contentsOfFile: path.path) { model.accept(image) }
            } label: {
                Label(language.text("Use test photo", "使用测试照片"), systemImage: "photo")
                    .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 48)
                    .foregroundStyle(LetterStyle.accent)
            }.buttonStyle(.plain)
            #endif
        case .valid:
            HStack(spacing: 16) {
                Button {
                    appendPage = true; model.capturePrompt(); cameraOpen = true
                } label: {
                    addPageCell(language.text("Next photo", "拍摄下一张"), icon: "camera")
                }.buttonStyle(.plain).accessibilityIdentifier("takeNextPage")
                PhotosPicker(selection: $selectedPhoto, matching: .images, preferredItemEncoding: .compatible) {
                    addPageCell(language.text("Library", "相册"), icon: "photo")
                }.buttonStyle(.plain).accessibilityIdentifier("choosePhoto")
            }.fixedSize(horizontal: false, vertical: true).disabled(!model.canAddPage)
            Button { model.interpret() } label: {
                HStack(spacing: 12) {
                    LetterScanIcon().stroke(.white, style: StrokeStyle(lineWidth: 1, lineCap: .round))
                        .frame(width: 25, height: 25).accessibilityHidden(true)
                    Text(language.text("Analyze document", "分析文档")).font(.title3.weight(.semibold))
                }.frame(maxWidth: .infinity, minHeight: 60).padding(.horizontal, 16)
                    .foregroundStyle(.white)
                    .background(LetterStyle.button, in: RoundedRectangle(cornerRadius: 20))
                    .shadow(color: LetterStyle.button.opacity(0.20), radius: 6, y: 3)
            }.buttonStyle(.plain).disabled(!model.canFinishCapture).accessibilityIdentifier("analyzeDocument")
            Text(language.text("Your photos are sent to AI only when you tap Analyze", "只有点击分析后，照片才会发送给 AI"))
                .font(.footnote).foregroundStyle(LetterStyle.supportingText)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
            if model.pages.count == 10 {
                Text(language.text("The 10-page limit has been reached.", "已达到每封信 10 页的上限。")).font(.callout)
            }
            #if TEST_BUILD
            Button(language.text("Add next test photo", "添加下一张测试照片")) {
                if let path = Bundle.main.url(forResource: "fictional-bill-page2", withExtension: "jpg"),
                   let image = UIImage(contentsOfFile: path.path) { model.accept(image, asNextPage: true) }
            }.buttonStyle(.bordered).frame(minHeight: 44).disabled(!model.canAddPage)
            #endif
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
    private var photoLibraryButton: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images, preferredItemEncoding: .compatible) {
            Group {
                if model.phase == .valid {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus").font(.title3)
                        Text(language.text("Choose next photo", "选择下一张照片"))
                            .font(.headline)
                    }
                } else {
                    Label(language.text("Choose a photo", "选择照片"), systemImage: "photo.badge.plus")
                        .font(.title3.weight(.semibold))
                }
            }
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: model.phase == .valid ? 76 : 60, maxHeight: model.phase == .valid ? .infinity : nil)
                .padding(.horizontal, model.phase == .valid ? 12 : 16).padding(.vertical, 8)
                .foregroundStyle(.primary)
                .background(LetterStyle.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(LetterStyle.rule, lineWidth: 1) }
        }
        .buttonStyle(.plain).accessibilityIdentifier("choosePhoto")
        .accessibilityLabel(language.text(model.phase == .valid ? "Choose next photo" : "Choose a photo", model.phase == .valid ? "选择下一张照片" : "选择照片"))
    }

    private func welcomeUploadLabel(_ title: String) -> some View {
        Label(title, systemImage: "square.and.arrow.up")
            .font(.title3.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 60)
            .padding(.horizontal, 12).foregroundStyle(LetterStyle.accent)
            .background(LetterStyle.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(LetterStyle.rule, lineWidth: 1) }
    }

    func primary(_ title: String, icon: String, showsArrow: Bool = false, cornerRadius: CGFloat = 8, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: 12) {
                        Image(systemName: icon).font(.title3)
                        Text(title).font(.title3.weight(.semibold))
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    HStack(spacing: 12) {
                        Image(systemName: icon).font(.title3)
                        Text(title).font(.title3.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        if showsArrow { Image(systemName: "arrow.right").accessibilityHidden(true) }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 60).padding(.horizontal, 16).padding(.vertical, 8)
            .foregroundStyle(.white)
            .background(LetterStyle.button, in: RoundedRectangle(cornerRadius: cornerRadius))
        }.buttonStyle(.plain).accessibilityLabel(title)
    }
    @ViewBuilder func explanation(_ result: LetterInterpretation) -> some View {
        if result.domain == "unsupported" {
            section(language.text("Unsupported letter", "暂不支持此类信件"), text: language.text("This first version supports medical and insurance letters.", "首个版本支持医疗和保险信件。"), icon: "info.circle")
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text(language.text("Your letter", "信件解读"))
                    .font(.subheadline.weight(.semibold)).foregroundStyle(LetterStyle.accent)
                Text(result.heading(language))
                    .font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
            }.padding(.vertical, 16)
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
                    primary(language.text("Add to Calendar", "添加到日历"), icon: "calendar.badge.plus", cornerRadius: 24) {
                        calendarProposal = CalendarProposal.make(action: action, facts: result.facts, language: language, document: result)
                    }
                    .accessibilityHint(language.text("Review the event details before saving.", "保存前先核对日历事项。"))
                    .accessibilityIdentifier("addActionToCalendar")
                    if action.status == "needs_verification" {
                        Text(language.text("Needs verification", "需要核实")).font(.callout)
                    }
                }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(LetterStyle.softMint, in: RoundedRectangle(cornerRadius: 8))
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
        VStack(alignment: .leading, spacing: 20) {
            Divider().overlay(LetterStyle.rule)
            Label(title, systemImage: icon).font(.headline).foregroundStyle(LetterStyle.accent).accessibilityAddTraits(.isHeader)
            Text(text).font(.title3).fixedSize(horizontal: false, vertical: true)
        }.padding(.vertical, 8).frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ZoomablePhotoView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> PhotoZoomScrollView {
        let view = PhotoZoomScrollView()
        view.delegate = context.coordinator
        view.minimumZoomScale = 1
        view.maximumZoomScale = 6
        view.bouncesZoom = true
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.imageView.image = image
        view.imageView.isAccessibilityElement = true
        view.imageView.accessibilityIdentifier = "zoomedPhoto"
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.doubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
        return view
    }
    func updateUIView(_ view: PhotoZoomScrollView, context: Context) {
        view.imageView.image = image
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            (scrollView as? PhotoZoomScrollView)?.imageView
        }
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            (scrollView as? PhotoZoomScrollView)?.centerPhoto()
        }
        @objc func doubleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? PhotoZoomScrollView else { return }
            if view.zoomScale > 1.01 {
                view.setZoomScale(1, animated: true)
            } else {
                let point = gesture.location(in: view.imageView)
                let width = view.bounds.width / 3
                let height = view.bounds.height / 3
                view.zoom(to: CGRect(x: point.x - width / 2, y: point.y - height / 2, width: width, height: height), animated: true)
            }
        }
    }
}

private final class PhotoZoomScrollView: UIScrollView {
    let imageView = UIImageView()
    private var fittedSize = CGSize.zero
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != fittedSize, bounds.width > 0, bounds.height > 0, let image = imageView.image {
            fittedSize = bounds.size
            setZoomScale(1, animated: false)
            let scale = min(bounds.width / image.size.width, bounds.height / image.size.height)
            imageView.frame = CGRect(origin: .zero, size: CGSize(width: image.size.width * scale, height: image.size.height * scale))
            contentSize = imageView.bounds.size
        }
        centerPhoto()
    }
    func centerPhoto() {
        // Let the outer pager receive horizontal swipes while the photo fits.
        panGestureRecognizer.isEnabled = zoomScale > 1.01
        let horizontal = max(0, (bounds.width - contentSize.width) / 2)
        let vertical = max(0, (bounds.height - contentSize.height) / 2)
        contentInset = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
}

// Vector scan icon based on the supplied SVG.
private struct LetterScanIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0.5, y: 5.83333))
        path.addLine(to: CGPoint(x: 0.5, y: 3.16667))
        path.addCurve(to: CGPoint(x: 3.16667, y: 0.5), control1: CGPoint(x: 0.5, y: 1.69391), control2: CGPoint(x: 1.69391, y: 0.5))
        path.addLine(to: CGPoint(x: 5.83333, y: 0.5))
        path.move(to: CGPoint(x: 19.1667, y: 0.5))
        path.addLine(to: CGPoint(x: 21.8333, y: 0.5))
        path.addCurve(to: CGPoint(x: 24.5, y: 3.16667), control1: CGPoint(x: 23.3061, y: 0.5), control2: CGPoint(x: 24.5, y: 1.69391))
        path.addLine(to: CGPoint(x: 24.5, y: 5.83333))
        path.move(to: CGPoint(x: 24.5, y: 19.1667))
        path.addLine(to: CGPoint(x: 24.5, y: 21.8333))
        path.addCurve(to: CGPoint(x: 21.8333, y: 24.5), control1: CGPoint(x: 24.5, y: 23.3061), control2: CGPoint(x: 23.3061, y: 24.5))
        path.addLine(to: CGPoint(x: 19.1667, y: 24.5))
        path.move(to: CGPoint(x: 5.83333, y: 24.5))
        path.addLine(to: CGPoint(x: 3.16667, y: 24.5))
        path.addCurve(to: CGPoint(x: 0.5, y: 21.8333), control1: CGPoint(x: 1.69391, y: 24.5), control2: CGPoint(x: 0.5, y: 23.3061))
        path.addLine(to: CGPoint(x: 0.5, y: 19.1667))
        for (y, endX) in [(7.16667, 16.5), (12.5, 19.1667), (17.8333, 13.8333)] {
            path.move(to: CGPoint(x: 5.83333, y: y))
            path.addLine(to: CGPoint(x: endX, y: y))
        }
        return path.applying(CGAffineTransform(scaleX: rect.width / 25, y: rect.height / 25).concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY)))
    }
}

// Light colors sampled from the reference screenshot in its Display P3 color space.
// Adaptive colors keep the same hierarchy in dark appearance.
enum LetterStyle {
    static let button = Color(uiColor: UIColor(displayP3Red: 45 / 255, green: 93 / 255, blue: 85 / 255, alpha: 1))
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.30, green: 0.76, blue: 0.68, alpha: 1)
            : UIColor(displayP3Red: 45 / 255, green: 93 / 255, blue: 85 / 255, alpha: 1)
    })
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.095, blue: 0.085, alpha: 1)
            : UIColor(displayP3Red: 247 / 255, green: 245 / 255, blue: 240 / 255, alpha: 1)
    })
    static let ink = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.90, green: 0.93, blue: 0.91, alpha: 1)
            : UIColor(displayP3Red: 35 / 255, green: 47 / 255, blue: 45 / 255, alpha: 1)
    })
    static let softMint = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.20, blue: 0.18, alpha: 1)
            : UIColor(displayP3Red: 229 / 255, green: 239 / 255, blue: 232 / 255, alpha: 1)
    })
    static let supportingText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.74, green: 0.81, blue: 0.78, alpha: 1)
            : UIColor(displayP3Red: 88 / 255, green: 100 / 255, blue: 95 / 255, alpha: 1)
    })
    static let rule = accent.opacity(0.20)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
}
