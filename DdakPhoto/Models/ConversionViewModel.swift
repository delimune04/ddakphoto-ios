import Foundation
import PhotosUI
import SwiftUI
import UIKit

struct PreparedPhoto: Identifiable {
    let id: UUID
    let thumbnail: UIImage?
    let sourceURL: URL
    let info: ImageInfo
    var result: ConversionResult?
    var error: String?
    var saved = false
}

enum WorkPhase {
    case idle, importing, converting, saving
}

struct UserNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

@MainActor
final class ConversionViewModel: ObservableObject {
    @Published private(set) var photos: [PreparedPhoto] = []
    @Published private(set) var phase: WorkPhase = .idle
    @Published private(set) var completedCount = 0
    @Published var banner: UserNotice?

    private var operationTotal = 0
    private var cancelRequested = false
    private var activeConversion: Task<ConversionResult, Error>?

    var isBusy: Bool { phase != .idle }
    var canConvert: Bool { !isBusy && !photos.isEmpty }
    var totalOriginalBytes: Int { photos.reduce(0) { $0 + $1.info.byteCount } }
    var totalResultBytes: Int { successfulResults.reduce(0) { $0 + $1.byteCount } }
    var successfulResults: [ConversionResult] { photos.compactMap(\.result) }
    var currentStatus: String {
        switch phase {
        case .idle: return ""
        case .importing: return "사진 가져오는 중 · \(completedCount)/\(operationTotal)"
        case .converting: return "사진 변환 중 · \(completedCount)/\(operationTotal)"
        case .saving: return "사진 앱에 저장하는 중"
        }
    }

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--demo") {
            Task { await loadDemoPhotos() }
        }
        #endif
    }

    func importPhotos(_ selection: [PhotosPickerItem]) async {
        guard !isBusy else { return }
        clearAll()
        guard !selection.isEmpty else { return }
        phase = .importing
        operationTotal = min(selection.count, 20)
        completedCount = 0
        var failures = 0
        for item in selection.prefix(20) {
            do {
                guard let imported = try await item.loadTransferable(type: ImportedPhoto.self) else {
                    throw PhotoWorkspaceError.unavailable
                }
                do {
                    let details = try await Self.inspectImportedPhoto(url: imported.url)
                    photos.append(PreparedPhoto(id: UUID(), thumbnail: UIImage(data: details.thumbnail),
                        sourceURL: imported.url, info: details.info))
                } catch {
                    PhotoWorkspace.remove(imported.url)
                    throw error
                }
            } catch {
                failures += 1
            }
            completedCount += 1
        }
        phase = .idle
        if failures > 0 {
            banner = UserNotice(title: "일부 사진을 가져오지 못했어요",
                message: "\(failures)장의 사진을 읽을 수 없었어요. iCloud 사진이라면 인터넷 연결을 확인한 뒤 다시 선택해 주세요. 가져온 사진은 계속 변환할 수 있어요.")
        }
    }

    func convert(settings: ConversionSettings) {
        guard canConvert else { return }
        invalidateResults()
        phase = .converting
        completedCount = 0
        operationTotal = photos.count
        cancelRequested = false
        Task {
            for index in photos.indices {
                if cancelRequested { break }
                let sourceURL = photos[index].sourceURL
                let task = Task.detached(priority: .userInitiated) {
                    try ImageProcessor().convert(sourceURL: sourceURL, settings: settings,
                        outputDirectory: PhotoWorkspace.outputDirectory)
                }
                activeConversion = task
                do {
                    let result = try await task.value
                    if cancelRequested {
                        PhotoWorkspace.remove(result.url)
                        break
                    }
                    photos[index].result = result
                } catch is CancellationError {
                    break
                } catch {
                    photos[index].error = error.localizedDescription
                }
                completedCount += 1
            }
            activeConversion = nil
            phase = .idle
            let failedCount = photos.filter { $0.error != nil }.count
            if failedCount > 0 {
                banner = UserNotice(title: "변환 결과를 확인해 주세요",
                    message: "\(failedCount)장은 변환하지 못했어요. 사진 아래 안내를 확인해 주세요. 나머지 결과는 저장하거나 공유할 수 있어요.")
            }
        }
    }

    func cancelConversion() {
        guard phase == .converting else { return }
        cancelRequested = true
        activeConversion?.cancel()
    }

    func invalidateResults() {
        guard !isBusy else { return }
        for index in photos.indices {
            if let result = photos[index].result { PhotoWorkspace.remove(result.url) }
            photos[index].result = nil
            photos[index].error = nil
            photos[index].saved = false
        }
    }

    func clearAll() {
        guard !isBusy else { return }
        for photo in photos {
            PhotoWorkspace.remove(photo.sourceURL)
            if let result = photo.result { PhotoWorkspace.remove(result.url) }
        }
        photos = []
        completedCount = 0
    }

    func saveAll() {
        let candidates = photos.filter { $0.result != nil && !$0.saved }
        save(ids: candidates.map(\.id), urls: candidates.compactMap { $0.result?.url })
    }

    func savePhoto(id: UUID) {
        guard let photo = photos.first(where: { $0.id == id }), !photo.saved,
              let result = photo.result else { return }
        save(ids: [id], urls: [result.url])
    }

    private func save(ids: [UUID], urls: [URL]) {
        guard !isBusy, !urls.isEmpty else { return }
        phase = .saving
        Task {
            do {
                try await PhotoLibrarySaver.save(fileURLs: urls)
                for index in photos.indices where ids.contains(photos[index].id) {
                    photos[index].saved = true
                }
                banner = UserNotice(title: "저장했어요", message: "\(urls.count)장의 새 사진을 사진 앱에 저장했어요. 원본 사진은 그대로 있어요.")
            } catch {
                banner = UserNotice(title: "사진을 저장하지 못했어요", message: error.localizedDescription)
            }
            phase = .idle
        }
    }

    private struct ImportedDetails: Sendable {
        let info: ImageInfo
        let thumbnail: Data
    }

    private static func inspectImportedPhoto(url: URL) async throws -> ImportedDetails {
        try await Task.detached(priority: .userInitiated) {
            let info = try ImageProcessor().inspect(url: url)
            let thumbnail = try PhotoWorkspace.thumbnailData(for: url)
            return ImportedDetails(info: info, thumbnail: thumbnail)
        }.value
    }

    #if DEBUG
    private func loadDemoPhotos() async {
        guard !isBusy, photos.isEmpty else { return }
        phase = .importing
        operationTotal = 2
        do {
            let urls = try await Task.detached { try DemoPhotoFactory.createPhotos() }.value
            for url in urls {
                let details = try await Self.inspectImportedPhoto(url: url)
                photos.append(PreparedPhoto(id: UUID(), thumbnail: UIImage(data: details.thumbnail),
                    sourceURL: url, info: details.info))
                completedCount += 1
            }
        } catch {
            banner = UserNotice(title: "샘플을 준비하지 못했어요", message: error.localizedDescription)
        }
        phase = .idle
        if ProcessInfo.processInfo.arguments.contains("--demo-results") {
            convert(settings: ConversionSettings(maxBytes: 500_000, maxLongEdge: 1920))
        }
    }
    #endif
}
