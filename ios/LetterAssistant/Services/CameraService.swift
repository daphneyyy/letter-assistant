import AVFoundation
import UIKit
import SwiftUI

// Use Apple's camera controls and photo confirmation instead of a custom shutter UI.
private struct SystemCamera: UIViewControllerRepresentable {
    let receive: (UIImage) -> Void
    let cancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .rear
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SystemCamera
        init(parent: SystemCamera) { self.parent = parent }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.cancel() }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let image = info[.originalImage] as? UIImage else { parent.cancel(); return }
            parent.receive(image)
        }
    }
}

struct CameraSheet: View {
    let language: AppLanguage
    let pageNumber: Int
    let receive: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var authorized = false
    @State private var checkingPermission = true

    var body: some View {
        Group {
            if authorized && UIImagePickerController.isSourceTypeAvailable(.camera) {
                SystemCamera(receive: { image in receive(image); dismiss() }, cancel: { dismiss() })
                    .ignoresSafeArea()
            } else {
                NavigationStack {
                    VStack(spacing: 20) {
                        if checkingPermission {
                            ProgressView()
                        } else {
                            ContentUnavailableView(language.text("Camera unavailable", "无法使用相机"), systemImage: "camera", description: Text(language.text("Allow Camera in Settings, or return and try again.", "请在设置中允许使用相机，或返回后重试。")))
                            Button(language.text("Open Settings", "打开设置")) {
                                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                            }.buttonStyle(.bordered).frame(minHeight: 44)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(LetterStyle.background.ignoresSafeArea())
                    .toolbar { ToolbarItem(placement: .cancellationAction) {
                        Button(language.text("Cancel", "取消")) { dismiss() }
                    } }
                }
            }
        }
        .task { await checkPermission() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await checkPermission() } }
        }
    }

    @MainActor private func checkPermission() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            checkingPermission = false; return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: authorized = true
        case .notDetermined: authorized = await AVCaptureDevice.requestAccess(for: .video)
        default: authorized = false
        }
        checkingPermission = false
    }
}
