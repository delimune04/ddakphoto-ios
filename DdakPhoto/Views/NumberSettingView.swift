import SwiftUI

enum CustomSetting: String, Identifiable {
    case size
    case dimensions

    var id: String { rawValue }
    var title: String { self == .size ? "최대 용량 직접 입력" : "최대 길이 직접 입력" }
    var unit: String { self == .size ? "KB" : "px" }
    var range: ClosedRange<Int> { self == .size ? 10...20_000 : 128...8_192 }
    var hint: String {
        self == .size
            ? "10~20,000 KB 사이의 정수를 입력하세요.\n1 MB는 1,000 KB로 계산해요."
            : "128~8,192 px 사이의 정수를 입력하세요.\n가로와 세로 중 긴 쪽의 최대 길이예요."
    }
}

struct NumberSettingView: View {
    let setting: CustomSetting
    let onCommit: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @FocusState private var inputFocused: Bool

    init(setting: CustomSetting, initialValue: Int, onCommit: @escaping (Int) -> Void) {
        self.setting = setting
        self.onCommit = onCommit
        _text = State(initialValue: initialValue == 0 ? "" : String(initialValue))
    }

    private var validValue: Int? {
        guard let value = Int(text), setting.range.contains(value) else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(setting.title)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        TextField("숫자 입력", text: $text)
                            .keyboardType(.numberPad)
                            .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .focused($inputFocused)
                            .accessibilityLabel(setting.title)
                        Text(setting.unit)
                            .font(.headline)
                            .foregroundStyle(AppTheme.secondary)
                    }
                    .padding(20)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18).stroke(AppTheme.line, lineWidth: 1)
                    }
                    Text(setting.hint)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if !text.isEmpty && validValue == nil {
                        Label("입력 가능한 범위의 정수를 확인해주세요.", systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundStyle(AppTheme.error)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Button {
                        guard let value = validValue else { return }
                        onCommit(value)
                        dismiss()
                    } label: {
                        Text("완료")
                    }
                    .buttonStyle(FilledActionStyle())
                    .disabled(validValue == nil)
                    .opacity(validValue == nil ? 0.45 : 1)
                }
                .padding(24)
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("취소") { dismiss() }
                        .foregroundStyle(AppTheme.secondary)
                }
            }
            .onAppear { inputFocused = true }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .tint(AppTheme.teal)
    }
}
