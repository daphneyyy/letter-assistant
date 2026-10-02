import AVFoundation
import UIKit
import SwiftUI

final class CameraService: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "letter.camera")
    @Published var ready = false
    @Published var failed = false
    @Published var taking = false
    var onPhoto: ((UIImage) -> Void)?
    private var configured = false
    func start() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] allowed in
            guard let self else { return }
            guard allowed else { DispatchQueue.main.async { self.failed = true }; return }
            self.queue.async {
                if !self.configured {
                    self.session.beginConfiguration(); self.session.sessionPreset = .photo
                    guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                          let input = try? AVCaptureDeviceInput(device: camera),
                          self.session.canAddInput(input), self.session.canAddOutput(self.output) else {
                        self.session.commitConfiguration()
                        DispatchQueue.main.async { self.failed = true }; return
                    }
                    self.session.addInput(input); self.session.addOutput(self.output)
                    self.session.commitConfiguration(); self.configured = true
                }
                self.session.startRunning()
                DispatchQueue.main.async { self.ready = true }
            }
        }
    }
    func stop() { queue.async { self.session.stopRunning() } }
    func capture() {
        guard ready, !taking else { return }; taking = true
        queue.async {
            if let connection = self.output.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let image = photo.fileDataRepresentation().flatMap(UIImage.init(data:))
        DispatchQueue.main.async {
            self.taking = false
            if let image, error == nil { self.onPhoto?(image) } else { self.failed = true }
        }
    }
}
private final class PreviewSurface: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var preview: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> UIView {
        let view = PreviewSurface(); view.preview.session = session; view.preview.videoGravity = .resizeAspect
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
struct CameraSheet: View {
    let language: AppLanguage
    let pageNumber: Int
    let receive: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraService()
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(language.text("Keep all four edges of the page visible. Hold still in good light.", "请拍到纸张的四边。保持手机稳定，确保光线充足。"))
                    .font(.title3).padding(.horizontal)
                if camera.failed {
                    ContentUnavailableView(language.text("Camera unavailable", "无法使用相机"), systemImage: "camera", description: Text(language.text("Allow Camera in Settings, or return and try again.", "请在设置中允许使用相机，或返回后重试。")))
                    Button(language.text("Open Settings", "打开设置")) { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }.buttonStyle(.bordered).frame(minHeight: 44)
                } else {
                    CameraPreview(session: camera.session).accessibilityHidden(true)
                    Button { camera.capture() } label: {
                        Label(language.text("Photograph page \(pageNumber)", "拍摄第 \(pageNumber) 页"), systemImage: "camera.fill").frame(maxWidth: .infinity, minHeight: 52)
                    }.buttonStyle(.borderedProminent).disabled(!camera.ready || camera.taking).padding()
                }
            }
            .navigationTitle(language.text("Photograph the letter", "拍摄信件"))
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(language.text("Cancel", "取消")) { dismiss() } } }
        }
        .onAppear { camera.onPhoto = { image in receive(image); dismiss() }; camera.start() }
        .onDisappear { camera.stop() }
    }
}
