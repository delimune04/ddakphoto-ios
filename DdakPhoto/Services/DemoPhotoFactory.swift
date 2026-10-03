#if DEBUG
import Foundation
import UIKit

/// Local fixtures used only by simulator verification and store capture scripts.
enum DemoPhotoFactory {
    static func createPhotos() throws -> [URL] {
        try FileManager.default.createDirectory(at: PhotoWorkspace.inputDirectory, withIntermediateDirectories: true)
        return try (0..<2).map { index in
            let size = CGSize(width: 2400, height: 3200)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = true
            let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
                let cg = context.cgContext
                let colors: [CGColor] = index == 0
                    ? [UIColor(red: 0.68, green: 0.86, blue: 0.88, alpha: 1).cgColor,
                       UIColor(red: 0.95, green: 0.91, blue: 0.77, alpha: 1).cgColor]
                    : [UIColor(red: 0.98, green: 0.82, blue: 0.67, alpha: 1).cgColor,
                       UIColor(red: 0.62, green: 0.74, blue: 0.68, alpha: 1).cgColor]
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) {
                    cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: 3200), options: [])
                }
                cg.setFillColor(UIColor(red: 0.98, green: 0.96, blue: 0.79, alpha: 1).cgColor)
                cg.fillEllipse(in: CGRect(x: 1550, y: 600, width: 400, height: 400))
                for layer in 0..<5 {
                    let path = UIBezierPath()
                    let base = CGFloat(1550 + layer * 300)
                    path.move(to: CGPoint(x: 0, y: base))
                    path.addCurve(to: CGPoint(x: 2400, y: base + 130), controlPoint1: CGPoint(x: 900, y: base - 650), controlPoint2: CGPoint(x: 1450, y: base + 500))
                    path.addLine(to: CGPoint(x: 2400, y: 3200))
                    path.addLine(to: CGPoint(x: 0, y: 3200))
                    path.close()
                    UIColor(red: 0.16 + CGFloat(layer) * 0.07, green: 0.39 + CGFloat(layer) * 0.05,
                        blue: 0.36 + CGFloat(layer) * 0.03, alpha: 1).setFill()
                    path.fill()
                }
            }
            guard let data = image.jpegData(compressionQuality: 0.95) else { throw PhotoWorkspaceError.unavailable }
            let url = PhotoWorkspace.inputDirectory.appendingPathComponent("sample-\(index + 1).jpg")
            try data.write(to: url, options: .atomic)
            return url
        }
    }
}
#endif
