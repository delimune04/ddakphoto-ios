import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("개인정보처리방침")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                        Text("작성일: 2026년 10월 3일")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondary)
                        Text("딱사진은 사진을 사용자의 기기 안에서 처리합니다. 앱에서 계정을 만들거나 사진을 개발자의 서버에 전송하지 않습니다.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    policySection("1. 앱에서 처리하는 정보", text: "사용자가 시스템 사진 선택 화면에서 고른 사진만 읽어 용량과 크기를 조절합니다. 사진과 원본 메타데이터는 기기 안에서 처리하며, 변환한 JPG에는 원본의 위치 정보 등의 메타데이터를 복사하지 않습니다. 광고, 분석, 추적 도구를 사용하지 않습니다.")
                    policySection("2. 사진 접근 권한", text: "사진 선택에는 시스템 사진 선택 화면을 사용합니다. 전체 사진 보관함 읽기 권한이나 위치 권한은 요청하지 않습니다. 사용자가 사진 앱에 저장할 때만 사진 추가 권한을 요청합니다. 저장 권한을 허용하지 않아도 변환과 파일 공유를 이용할 수 있습니다. iCloud에만 있는 사진을 가져올 때는 Apple 사진 서비스의 다운로드가 필요할 수 있습니다.")
                    policySection("3. 임시 파일과 삭제", text: "선택한 사진의 작업용 사본과 변환 결과를 앱의 임시 저장 공간에 보관합니다. ‘비우기’를 누르거나 새 사진을 선택하면 현재 작업용 파일을 지웁니다. 다음 앱 실행 시에도 이전 작업용 파일을 정리합니다. 원본 사진, 사용자가 사진 앱에 저장한 사진, 다른 앱에 공유한 사본은 이 정리로 삭제되지 않습니다.")
                    policySection("4. 공유와 Apple 서비스", text: "공유 버튼을 누르면 사용자가 시스템 공유 메뉴에서 선택한 앱이나 서비스에 사본을 전달합니다. 이후에는 해당 서비스의 개인정보 처리방침이 적용됩니다. 앱 구매와 결제는 Apple App Store가 처리하며, 딱사진 앱은 결제 정보를 입력받지 않습니다. Apple 서비스에는 Apple의 개인정보 처리방침이 적용됩니다.")
                    policySection("5. 지원 문의", text: "사용자가 이메일로 문의하면 문의에 포함한 이메일 주소와 내용을 지원 답변을 위해 사용할 수 있습니다. 사진이나 민감한 정보가 필요하지 않은 문의에는 이를 첨부하지 않아도 됩니다. 문의 메일에는 사용하는 이메일 서비스의 정책이 적용됩니다. 문의와 개인정보 관련 요청은 아래 주소로 보내주세요.")
                    if let mailURL = URL(string: "mailto:sp040122@gmail.com") {
                        Link("sp040122@gmail.com", destination: mailURL)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.teal)
                    }
                    if let policyURL = URL(string: "https://ddakphoto-support.sp040122.chatgpt.site/privacy.html") {
                        Link("웹에서 개인정보처리방침 보기", destination: policyURL)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.teal)
                    }
                    policySection("6. 정책 변경", text: "앱의 데이터 처리 방식이 변경되면 이 정책과 App Store 개인정보 공개 정보를 함께 업데이트합니다.")
                }
                .padding(24)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .navigationTitle("개인정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") { dismiss() }
                }
            }
        }
        .tint(AppTheme.teal)
        .presentationDragIndicator(.visible)
    }

    private func policySection(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
