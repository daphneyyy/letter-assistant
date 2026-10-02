import UIKit
import Vision

struct PreparedPhoto {
    let bytes: Data
    let image: UIImage
}
enum PageQualityService {
    // Render full-sized, oriented pixels into a new JPEG, stripping capture metadata.
    static func prepare(_ source: UIImage) throws -> PreparedPhoto {
        let size = CGSize(width: source.size.width * source.scale, height: source.size.height * source.scale)
        guard min(size.width, size.height) >= 800 else { throw RelayError(code: "photo_too_small") }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            source.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let bytes = image.jpegData(compressionQuality: 0.95), bytes.count <= 10 * 1024 * 1024 else {
            throw RelayError(code: "photo_too_large")
        }
        return PreparedPhoto(bytes: bytes, image: image)
    }
    static func inspect(_ bytes: Data) throws {
        let request = VNRecognizeTextRequest(); request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        let rectangle = VNDetectRectanglesRequest(); rectangle.minimumConfidence = 0.5
        rectangle.minimumSize = 0.3; rectangle.maximumObservations = 1
        try VNImageRequestHandler(data: bytes).perform([request, rectangle])
        let lines = request.results ?? []
        let readable = lines.compactMap { $0.topCandidates(1).first }.filter { $0.confidence >= 0.3 }
        guard readable.reduce(0, { $0 + $1.string.count }) >= 20 else { throw RelayError(code: "photo_unreadable") }
        // Conservative local signals; final readability/crop verdict comes from the image model.
        let touchesEdge = lines.contains { line in
            let b = line.boundingBox
            return b.minX < 0.005 || b.maxX > 0.995 || b.minY < 0.005 || b.maxY > 0.995
        }
        if touchesEdge { throw RelayError(code: "photo_cropped") }
    }
}
