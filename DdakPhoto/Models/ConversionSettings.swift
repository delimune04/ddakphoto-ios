import Foundation

/// A limit of nil keeps the source size unless a smaller image is needed to fit
/// the byte budget. Large images are also bounded by the decoder's memory limit.
struct ConversionSettings: Equatable, Sendable {
    let maxBytes: Int
    let maxLongEdge: Int?

    init(maxBytes: Int, maxLongEdge: Int? = nil) {
        self.maxBytes = maxBytes
        self.maxLongEdge = maxLongEdge
    }
}

struct ImageInfo: Equatable, Sendable {
    /// Dimensions after applying the source's EXIF orientation.
    let width: Int
    let height: Int
    let byteCount: Int
}

struct ConversionResult: Equatable, Sendable {
    let url: URL
    let byteCount: Int
    let width: Int
    let height: Int
}
