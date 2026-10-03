import XCTest
import ImageIO
import UIKit
import UniformTypeIdentifiers
@testable import DdakPhoto

final class ImageProcessorTests: XCTestCase {
    private var directory: URL!
    private let processor = ImageProcessor()

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let directory { try FileManager.default.removeItem(at: directory) }
        directory = nil
    }

    func testNoisyImageFitsRequestedBytesAndPreservesOriginal() throws {
        let sourceURL = try writeImage(makeNoiseImage(width: 1_280, height: 960), type: .jpeg)
        let original = try Data(contentsOf: sourceURL)
        let result = try processor.convert(
            sourceURL: sourceURL,
            settings: ConversionSettings(maxBytes: 7_500),
            outputDirectory: directory.appendingPathComponent("converted")
        )

        XCTAssertLessThanOrEqual(result.byteCount, 7_500)
        XCTAssertEqual(try Data(contentsOf: result.url).count, result.byteCount)
        XCTAssertLessThan(max(result.width, result.height), 1_280)
        XCTAssertGreaterThan(result.width, 0)
        XCTAssertGreaterThan(result.height, 0)
        XCTAssertEqual(try Data(contentsOf: sourceURL), original)
        XCTAssertNotEqual(sourceURL, result.url)
        XCTAssertEqual(result.url.pathExtension, "jpg")
        let output = try XCTUnwrap(CGImageSourceCreateWithURL(result.url as CFURL, nil))
        XCTAssertEqual(CGImageSourceGetType(output) as String?, UTType.jpeg.identifier)
    }

    func testLongEdgeLimitAndResultDimensionsMatchWrittenJPEG() throws {
        let sourceURL = try writeImage(makeNoiseImage(width: 480, height: 360), type: .png)
        let result = try processor.convert(
            sourceURL: sourceURL,
            settings: ConversionSettings(maxBytes: 1_000_000, maxLongEdge: 120),
            outputDirectory: directory
        )

        XCTAssertEqual(result.width, 120)
        XCTAssertEqual(result.height, 90)
        let info = try processor.inspect(url: result.url)
        XCTAssertEqual(info.width, result.width)
        XCTAssertEqual(info.height, result.height)
        XCTAssertEqual(info.byteCount, result.byteCount)
    }

    func testSmallSourceIsNeverEnlarged() throws {
        let sourceURL = try writeImage(makeNoiseImage(width: 40, height: 30), type: .png)
        let result = try processor.convert(
            sourceURL: sourceURL,
            settings: ConversionSettings(maxBytes: 1_000_000, maxLongEdge: 2_000),
            outputDirectory: directory
        )
        XCTAssertEqual(result.width, 40)
        XCTAssertEqual(result.height, 30)
    }

    func testEXIFOrientationIsAppliedAndPrivateMetadataIsRemoved() throws {
        let sourceURL = try writeImage(
            makeNoiseImage(width: 120, height: 80),
            type: .jpeg,
            properties: [
                kCGImagePropertyOrientation: 6,
                kCGImagePropertyGPSDictionary: [
                    kCGImagePropertyGPSLatitude: 37.5,
                    kCGImagePropertyGPSLatitudeRef: "N",
                    kCGImagePropertyGPSLongitude: 127.0,
                    kCGImagePropertyGPSLongitudeRef: "E"
                ],
                kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: "2026:10:03 12:00:00"],
                kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFArtist: "Private name"]
            ]
        )
        let originalInfo = try processor.inspect(url: sourceURL)
        XCTAssertEqual(originalInfo.width, 80)
        XCTAssertEqual(originalInfo.height, 120)

        let result = try processor.convert(
            sourceURL: sourceURL,
            settings: ConversionSettings(maxBytes: 100_000),
            outputDirectory: directory
        )
        XCTAssertEqual(result.width, 80)
        XCTAssertEqual(result.height, 120)
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(result.url as CFURL, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        XCTAssertNil(properties[kCGImagePropertyGPSDictionary])
        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        XCTAssertNil(exif?[kCGImagePropertyExifDateTimeOriginal])
        let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        XCTAssertNil(tiff?[kCGImagePropertyTIFFArtist])
        XCTAssertEqual((properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1, 1)
    }

    func testTransparentPNGBecomesWhiteBackgroundJPEG() throws {
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: 64,
            height: 64,
            bitsPerComponent: 8,
            bytesPerRow: 64 * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.clear(CGRect(x: 0, y: 0, width: 64, height: 64))
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(x: 24, y: 24, width: 16, height: 16))
        let sourceURL = try writeImage(try XCTUnwrap(context.makeImage()), type: .png)
        let result = try processor.convert(
            sourceURL: sourceURL,
            settings: ConversionSettings(maxBytes: 100_000),
            outputDirectory: directory
        )
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(result.url as CFURL, nil))
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let corner = try rgbPixel(image: image, x: 2, y: 2)
        XCTAssertGreaterThan(corner.0, 245)
        XCTAssertGreaterThan(corner.1, 245)
        XCTAssertGreaterThan(corner.2, 245)
    }

    func testOutputWriteFailureDoesNotModifySourceOrLeavePartialOutput() throws {
        let sourceURL = try writeImage(makeNoiseImage(width: 60, height: 40), type: .png)
        let original = try Data(contentsOf: sourceURL)
        let blocker = directory.appendingPathComponent("not-a-directory")
        try Data("blocker".utf8).write(to: blocker)

        XCTAssertThrowsError(try processor.convert(
            sourceURL: sourceURL,
            settings: ConversionSettings(maxBytes: 100_000),
            outputDirectory: blocker
        )) { error in
            guard case ImageProcessorError.cannotWriteOutput = error else {
                return XCTFail("Expected a write error, received \(error)")
            }
        }
        XCTAssertEqual(try Data(contentsOf: sourceURL), original)
        XCTAssertEqual(try Data(contentsOf: blocker), Data("blocker".utf8))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path).count, 2)
    }

    func testImpossibleByteBudgetFailsWithoutOutput() throws {
        let sourceURL = try writeImage(makeNoiseImage(width: 60, height: 40), type: .png)
        let outputDirectory = directory.appendingPathComponent("converted")
        XCTAssertThrowsError(try processor.convert(
            sourceURL: sourceURL,
            settings: ConversionSettings(maxBytes: 1),
            outputDirectory: outputDirectory
        )) { error in
            guard case ImageProcessorError.targetTooSmall = error else {
                return XCTFail("Expected a byte-budget error, received \(error)")
            }
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: outputDirectory.path))
    }

    func testInvalidInputIsRejected() throws {
        let sourceURL = directory.appendingPathComponent("broken.jpg")
        try Data("not an image".utf8).write(to: sourceURL)
        XCTAssertThrowsError(try processor.inspect(url: sourceURL))
        XCTAssertThrowsError(try processor.convert(
            sourceURL: sourceURL,
            settings: ConversionSettings(maxBytes: 100_000),
            outputDirectory: directory
        ))
    }

    func testCancelledConversionDoesNotWriteOutput() async throws {
        let sourceURL = try writeImage(makeNoiseImage(width: 60, height: 40), type: .png)
        let outputDirectory = directory.appendingPathComponent("converted")
        let task = Task.detached { () throws -> ConversionResult in
            withUnsafeCurrentTask { $0?.cancel() }
            return try ImageProcessor().convert(
                sourceURL: sourceURL,
                settings: ConversionSettings(maxBytes: 100_000),
                outputDirectory: outputDirectory
            )
        }
        do {
            _ = try await task.value
            XCTFail("A cancelled task must not complete conversion.")
        } catch is CancellationError {
            // Expected: no conversion work or output survives cancellation.
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: outputDirectory.path))
    }

    func testHEICConvertsWhenEncoderIsAvailable() throws {
        let availableTypes = CGImageDestinationCopyTypeIdentifiers() as? [String] ?? []
        try XCTSkipUnless(availableTypes.contains(UTType.heic.identifier), "HEIC encoder is unavailable on this test device.")
        let sourceURL = try writeImage(makeNoiseImage(width: 160, height: 120), type: .heic)
        let result = try processor.convert(
            sourceURL: sourceURL,
            settings: ConversionSettings(maxBytes: 100_000),
            outputDirectory: directory
        )
        XCTAssertLessThanOrEqual(result.byteCount, 100_000)
        XCTAssertEqual(result.width, 160)
        XCTAssertEqual(result.height, 120)
    }

    private func makeNoiseImage(width: Int, height: Int) throws -> CGImage {
        // Deterministic noise is deliberately hard to compress, exercising the
        // downsampling path rather than testing only tiny flat-color JPEGs.
        var state: UInt32 = 0xC0FFEE
        var bytes = [UInt8](repeating: 255, count: width * height * 4)
        for index in stride(from: 0, to: bytes.count, by: 4) {
            for channel in 0..<3 {
                state = 1_664_525 &* state &+ 1_013_904_223
                bytes[index + channel] = UInt8(truncatingIfNeeded: state >> 24)
            }
        }
        let provider = try XCTUnwrap(CGDataProvider(data: Data(bytes) as CFData))
        return try XCTUnwrap(CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ))
    }

    private func writeImage(
        _ image: CGImage,
        type: UTType,
        properties: [CFString: Any] = [:]
    ) throws -> URL {
        let url = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension(type.preferredFilenameExtension ?? "image")
        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil))
        var properties = properties
        properties[kCGImageDestinationLossyCompressionQuality] = 1.0
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return url
    }

    private func rgbPixel(image: CGImage, x: Int, y: Int) throws -> (UInt8, UInt8, UInt8) {
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: image.width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height)))
        let bytes = try XCTUnwrap(context.data).assumingMemoryBound(to: UInt8.self)
        let offset = y * context.bytesPerRow + x * 4
        return (bytes[offset], bytes[offset + 1], bytes[offset + 2])
    }
}
