import Foundation
import Photos

enum PhotoLibrarySaver {
    /// Adds new assets; neither the selected originals nor converted files move.
    static func save(fileURLs: [URL]) async throws {
        guard !fileURLs.isEmpty else { return }
        try Task.checkCancellation()
        guard fileURLs.allSatisfy({ $0.isFileURL && FileManager.default.isReadableFile(atPath: $0.path) }) else {
            throw PhotoLibrarySaveError.invalidFile
        }

        var status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            status = await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { grantedStatus in
                    continuation.resume(returning: grantedStatus)
                }
            }
        }
        guard status == .authorized || status == .limited else {
            throw PhotoLibrarySaveError.permissionDenied
        }
        try Task.checkCancellation()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                for url in fileURLs {
                    let request = PHAssetCreationRequest.forAsset()
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = false
                    request.addResource(with: .photo, fileURL: url, options: options)
                }
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: PhotoLibrarySaveError.saveFailed(error?.localizedDescription))
                }
            }
        }
    }
}

enum PhotoLibrarySaveError: LocalizedError {
    case permissionDenied
    case invalidFile
    case saveFailed(String?)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "사진 보관함에 저장할 권한이 없어요. 설정에서 딱사진의 사진 추가 권한을 허용해 주세요. 공유 메뉴로 파일을 저장할 수도 있어요."
        case .invalidFile:
            return "저장할 사진 파일을 찾을 수 없어요. 사진을 다시 변환해 주세요."
        case .saveFailed(let detail):
            if let detail, !detail.isEmpty {
                return "사진 보관함에 저장하지 못했어요. \(detail)"
            }
            return "사진 보관함에 저장하지 못했어요. 저장 공간을 확인하고 다시 시도해 주세요."
        }
    }
}
