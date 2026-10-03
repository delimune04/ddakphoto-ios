import CoreTransferable
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum PhotoWorkspaceError: LocalizedError {
    case unavailable
    var errorDescription: String? { "사진 파일을 읽을 수 없어요. 다른 사진을 선택해 주세요." }
}

enum PhotoWorkspace {
    private static var rootDirectory: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("DdakPhoto", isDirectory: true)
    }
    static var inputDirectory: URL { rootDirectory.appendingPathComponent("Inputs", isDirectory: true) }
    static var outputDirectory: URL { rootDirectory.appendingPathComponent("Outputs", isDirectory: true) }

    static func cleanPreviousSession() {
        try? FileManager.default.removeItem(at: rootDirectory)
        try? FileManager.default.createDirectory(at: inputDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    }

    static func copyImportedFile(_ source: URL) throws -> URL {
        try FileManager.default.createDirectory(at: inputDirectory, withIntermediateDirectories: true)
        let suffix = source.pathExtension.isEmpty ? "image" : source.pathExtension
        let target = inputDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(suffix)
        try FileManager.default.copyItem(at: source, to: target)
        return target
    }

    static func remove(_ url: URL) {
        // Only delete files inside the app's own temporary workspace.
        guard url.standardizedFileURL.path.hasPrefix(rootDirectory.standardizedFileURL.path + "/") else { return }
        try? FileManager.default.removeItem(at: url)
    }

    static func thumbnailData(for url: URL) throws -> Data {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 320,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { throw PhotoWorkspaceError.unavailable }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw PhotoWorkspaceError.unavailable
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw PhotoWorkspaceError.unavailable }
        return data as Data
    }
}

struct ImportedPhoto: Transferable, Sendable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { receivedFile in
            ImportedPhoto(url: try PhotoWorkspace.copyImportedFile(receivedFile.file))
        }
    }
}
