import SwiftUI

enum AppTheme {
    static let canvas = Color(red: 246 / 255, green: 245 / 255, blue: 241 / 255)
    static let ink = Color(red: 24 / 255, green: 38 / 255, blue: 36 / 255)
    static let teal = Color(red: 32 / 255, green: 105 / 255, blue: 93 / 255)
    static let lime = Color(red: 231 / 255, green: 240 / 255, blue: 203 / 255)
    static let secondary = Color(red: 106 / 255, green: 115 / 255, blue: 109 / 255)
    static let line = Color(red: 224 / 255, green: 228 / 255, blue: 219 / 255)
    static let error = Color(red: 167 / 255, green: 62 / 255, blue: 48 / 255)

    static func bytes(_ count: Int) -> String {
        let kilobytes = Double(count) / 1_000
        if kilobytes >= 1_000 {
            return (kilobytes / 1_000).formatted(.number.precision(.fractionLength(1))) + " MB"
        }
        return kilobytes.formatted(.number.precision(.fractionLength(0...1))) + " KB"
    }

    static func dimensions(width: Int, height: Int) -> String {
        "\(width) × \(height)"
    }
}

struct FilledActionStyle: ButtonStyle {
    var prominent = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded, weight: .semibold))
            .padding(.vertical, 17)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .foregroundStyle(prominent ? .white : AppTheme.teal)
            .background(prominent ? AppTheme.teal : AppTheme.lime)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(21)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 23, style: .continuous)
                    .stroke(AppTheme.line.opacity(0.65), lineWidth: 1)
            }
    }
}

extension View {
    func cardSurface() -> some View {
        modifier(CardSurface())
    }
}
