import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

/// Uses an ImageIO thumbnail decoder so a full-resolution UIImage is never
/// retained. Keep batch work sequential and call this off the main actor.
struct ImageProcessor: Sendable {
    private let maximumWorkingPixels = 20_000_000.0
    private let maximumWorkingEdge = 8_192
    private let minimumQuality = 0.15
    private let maximumQuality = 0.95

    func inspect(url: URL) throws -> ImageInfo {
        try Task.checkCancellation()
        let source = try imageSource(url: url)
        let dimensions = try orientedDimensions(source: source)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let byteCount = (attributes[.size] as? NSNumber)?.intValue else {
            throw ImageProcessorError.unreadableImage
        }
        return ImageInfo(width: dimensions.width, height: dimensions.height, byteCount: byteCount)
    }

    func convert(
        sourceURL: URL,
        settings: ConversionSettings,
        outputDirectory: URL
    ) throws -> ConversionResult {
        guard settings.maxBytes > 0 else {
            throw ImageProcessorError.invalidSettings("목표 용량은 0보다 커야 해요.")
        }
        if let edge = settings.maxLongEdge, edge <= 0 {
            throw ImageProcessorError.invalidSettings("사진 크기는 0보다 커야 해요.")
        }
        guard outputDirectory.isFileURL else {
            throw ImageProcessorError.cannotWriteOutput
        }

        try Task.checkCancellation()
        let source = try imageSource(url: sourceURL)
        let dimensions = try orientedDimensions(source: source)
        let sourceEdge = max(dimensions.width, dimensions.height)
        let pixelCount = Double(dimensions.width) * Double(dimensions.height)
        let memoryScale = min(1.0, sqrt(maximumWorkingPixels / pixelCount))
        let safeEdge = max(1, Int((Double(sourceEdge) * memoryScale).rounded(.down)))
        var requestedEdge = min(min(sourceEdge, safeEdge), maximumWorkingEdge)
        if let userEdge = settings.maxLongEdge {
            requestedEdge = min(requestedEdge, userEdge)
        }

        var accepted: Candidate?
        while accepted == nil {
            try Task.checkCancellation()
            let attempt = try autoreleasepool {
                try encodeAtEdge(source: source, edge: requestedEdge, maxBytes: settings.maxBytes)
            }
            if attempt.data.count <= settings.maxBytes {
                accepted = attempt
                break
            }

            guard requestedEdge > 1 else {
                throw ImageProcessorError.targetTooSmall(minimumBytes: attempt.data.count)
            }
            // A slightly conservative scale avoids many decodes for small byte
            // budgets. Each pass decodes from the source, avoiding repeated JPEG
            // recompression and ensuring progress even for unusually noisy images.
            let ratio = sqrt(Double(settings.maxBytes) / Double(attempt.data.count)) * 0.9
            let scale = max(0.1, min(0.8, ratio))
            requestedEdge = max(1, min(requestedEdge - 1, Int(Double(requestedEdge) * scale)))
        }

        guard let accepted else {
            throw ImageProcessorError.cannotEncode
        }
        try Task.checkCancellation()

        // A random name prevents a source or another conversion from ever being
        // replaced. Atomic writes leave no partially written output on failure.
        let outputURL = outputDirectory.appendingPathComponent("ddakphoto-\(UUID().uuidString).jpg")
        do {
            try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
            try accepted.data.write(to: outputURL, options: .atomic)
            try Task.checkCancellation()
        } catch {
            try? FileManager.default.removeItem(at: outputURL)
            if error is CancellationError { throw error }
            throw ImageProcessorError.cannotWriteOutput
        }
        return ConversionResult(
            url: outputURL,
            byteCount: accepted.data.count,
            width: accepted.width,
            height: accepted.height
        )
    }

    private func imageSource(url: URL) throws -> CGImageSource {
        guard url.isFileURL,
              let source = CGImageSourceCreateWithURL(
                url as CFURL,
                [kCGImageSourceShouldCache: false] as CFDictionary
              ),
              CGImageSourceGetCount(source) > 0 else {
            throw ImageProcessorError.unreadableImage
        }
        return source
    }

    private func orientedDimensions(source: CGImageSource) throws -> (width: Int, height: Int) {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
              let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
              width > 0, height > 0 else {
            throw ImageProcessorError.unreadableImage
        }
        let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
        return (5...8).contains(orientation) ? (height, width) : (width, height)
    }

    private func encodeAtEdge(source: CGImageSource, edge: Int, maxBytes: Int) throws -> Candidate {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: edge,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw ImageProcessorError.unreadableImage
        }
        let image = try flattenTransparency(in: thumbnail)
        try Task.checkCancellation()
        let highQualityData = try jpegData(image: image, quality: maximumQuality)
        if highQualityData.count <= maxBytes {
            return Candidate(data: highQualityData, width: image.width, height: image.height)
        }

        let lowQualityData = try jpegData(image: image, quality: minimumQuality)
        guard lowQualityData.count <= maxBytes else {
            return Candidate(data: lowQualityData, width: image.width, height: image.height)
        }

        var lower = minimumQuality
        var upper = maximumQuality
        var best = lowQualityData
        // Keep the actual fitting bytes, since JPEG encoders need not produce a
        // perfectly monotonic byte count for every adjacent quality setting.
        for _ in 0..<8 {
            try Task.checkCancellation()
            let quality = (lower + upper) / 2
            let data = try jpegData(image: image, quality: quality)
            if data.count <= maxBytes {
                best = data
                lower = quality
            } else {
                upper = quality
            }
        }
        return Candidate(data: best, width: image.width, height: image.height)
    }

    private func flattenTransparency(in image: CGImage) throws -> CGImage {
        let hasAlpha: Bool
        switch image.alphaInfo {
        case .premultipliedLast, .premultipliedFirst, .last, .first, .alphaOnly:
            hasAlpha = true
        default:
            hasAlpha = false
        }
        guard hasAlpha else { return image }

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: image.width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
              ) else {
            throw ImageProcessorError.cannotEncode
        }
        let rect = CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height))
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(rect)
        context.draw(image, in: rect)
        guard let flattened = context.makeImage() else {
            throw ImageProcessorError.cannotEncode
        }
        return flattened
    }

    private func jpegData(image: CGImage, quality: Double) throws -> Data {
        try autoreleasepool {
            let data = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                data as CFMutableData,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            ) else {
                throw ImageProcessorError.cannotEncode
            }
            // No source properties are copied: location, camera details, dates,
            // and EXIF orientation are removed. Pixels are already upright.
            let properties = [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
            CGImageDestinationAddImage(destination, image, properties)
            guard CGImageDestinationFinalize(destination) else {
                throw ImageProcessorError.cannotEncode
            }
            return data as Data
        }
    }

    private struct Candidate {
        let data: Data
        let width: Int
        let height: Int
    }
}

enum ImageProcessorError: LocalizedError, Sendable {
    case invalidSettings(String)
    case unreadableImage
    case cannotEncode
    case cannotWriteOutput
    case targetTooSmall(minimumBytes: Int)

    var errorDescription: String? {
        switch self {
        case .invalidSettings(let message):
            return message
        case .unreadableImage:
            return "사진을 읽을 수 없어요. JPG, HEIC 또는 PNG 사진을 다시 선택해 주세요."
        case .cannotEncode:
            return "사진을 JPG로 변환하지 못했어요. 다른 사진으로 다시 시도해 주세요."
        case .cannotWriteOutput:
            return "변환한 사진을 저장하지 못했어요. 기기의 저장 공간을 확인해 주세요."
        case .targetTooSmall(let minimumBytes):
            return "목표 용량이 너무 작아요. 최소 \(minimumBytes)바이트보다 큰 용량을 설정해 주세요."
        }
    }
}
