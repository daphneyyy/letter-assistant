import UIKit
import PDFKit
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
        try VNImageRequestHandler(data: bytes).perform([request])
        let lines = request.results ?? []
        let candidates = lines.compactMap { $0.topCandidates(1).first }
        let readable = candidates.filter { $0.confidence >= 0.6 }
        let recognizedCount = candidates.reduce(0) { $0 + $1.string.count }
        let readableCount = readable.reduce(0) { $0 + $1.string.count }
        guard recognizedCount >= 20 else { throw RelayError(code: "photo_unreadable") }
        guard readableCount >= 30,
              Double(readableCount) / Double(max(1, recognizedCount)) >= 0.7,
              textSharpness(bytes, regions: lines.map(\.boundingBox)) >= 0.35 else {
            throw RelayError(code: "photo_quality_uncertain")
        }
    }

    // Measure fine edges inside recognized text, not sharp borders or screen chrome.
    // OCR can confidently guess words even when motion blur makes the photo unreadable.
    private static func textSharpness(_ bytes: Data, regions: [CGRect]) -> Double {
        guard let source = UIImage(data: bytes)?.cgImage else { return 0 }
        let scale = min(1, 1600.0 / Double(max(source.width, source.height)))
        let width = Int(Double(source.width) * scale), height = Int(Double(source.height) * scale)
        var pixels = [UInt8](repeating: 0, count: width * height)
        let rendered = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return false }
            context.interpolationQuality = .high
            context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard rendered else { return 0 }
        // Smaller lines represent body text; large logos must not hide blurred paragraphs.
        let heights = regions.map(\.height).sorted()
        let medianHeight = heights.isEmpty ? 0 : heights[heights.count / 2]
        var laplacianEnergy = 0.0, gradientEnergy = 0.0
        for box in regions where box.height <= medianHeight * 1.8 {
            let minX = max(1, Int(box.minX * Double(width)))
            let maxX = min(width - 2, Int(box.maxX * Double(width)))
            let minY = max(1, Int((1 - box.maxY) * Double(height)))
            let maxY = min(height - 2, Int((1 - box.minY) * Double(height)))
            guard minX < maxX, minY < maxY else { continue }
            for y in minY...maxY {
                for x in minX...maxX {
                    let i = y * width + x
                    let center = Double(pixels[i])
                    let left = Double(pixels[i - 1]), right = Double(pixels[i + 1])
                    let up = Double(pixels[i - width]), down = Double(pixels[i + width])
                    let dx = right - left, dy = down - up
                    let laplacian = left + right + up + down - 4 * center
                    // Weak gradients are dominated by sensor/screen noise, which
                    // otherwise inflates sharpness even on motion-blurred text.
                    guard dx * dx + dy * dy >= 1600 else { continue }
                    gradientEnergy += dx * dx + dy * dy
                    laplacianEnergy += laplacian * laplacian
                }
            }
        }
        return gradientEnergy > 0 ? laplacianEnergy / gradientEnergy : 0
    }
}

/// Render selected documents locally; only the resulting pages reach the AI request.
enum LetterFileImport {
    @MainActor static func images(from url: URL, maximumPages: Int = 10) throws -> [UIImage] {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size <= 30 * 1024 * 1024 else { throw RelayError(code: "file_too_large") }
        if url.pathExtension.lowercased() != "pdf" {
            guard let image = UIImage(contentsOfFile: url.path) else { throw RelayError(code: "invalid_file") }
            return [image]
        }
        guard let document = PDFDocument(url: url), !document.isLocked, document.pageCount > 0 else {
            throw RelayError(code: "invalid_file")
        }
        guard document.pageCount <= maximumPages else { throw RelayError(code: "too_many_pages") }
        return try (0..<document.pageCount).map { index in
            guard let page = document.page(at: index) else { throw RelayError(code: "invalid_file") }
            let bounds = page.bounds(for: .mediaBox)
            guard bounds.width > 0, bounds.height > 0, bounds.width.isFinite, bounds.height.isFinite else { throw RelayError(code: "invalid_file") }
            let scale = 2400 / max(bounds.width, bounds.height)
            let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
            let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
            return UIGraphicsImageRenderer(size: size, format: format).image { context in
                UIColor.white.setFill(); context.fill(CGRect(origin: .zero, size: size))
                context.cgContext.translateBy(x: 0, y: size.height)
                context.cgContext.scaleBy(x: scale, y: -scale)
                context.cgContext.translateBy(x: -bounds.minX, y: -bounds.minY)
                page.draw(with: .mediaBox, to: context.cgContext)
            }
        }
    }
}
