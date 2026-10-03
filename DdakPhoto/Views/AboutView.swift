import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showsPrivacyPolicy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 9) {
                        Text("딱 필요한 만큼,\n가볍게.")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.ink)
                        Text("사진 용량과 크기를 맞추는 작은 도구, 딱사진입니다.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: 23) {
                        aboutItem(icon: "iphone", title: "기기 안에서만 처리", message: "사진을 서버에 보내지 않아요. 로그인이나 인터넷 연결 없이 변환할 수 있어요.")
                        aboutItem(icon: "photo.on.rectangle", title: "원본은 그대로", message: "선택한 사진만 읽고 새로운 JPG를 만들어요. 사진 앱에 저장할 때도 원본을 덮어쓰지 않아요.")
                        aboutItem(icon: "location.slash", title: "위치 정보 제거", message: "새로 만든 JPG에는 촬영 위치 등의 원본 메타데이터를 넣지 않아요.")
                        aboutItem(icon: "checkmark.seal", title: "한 번 구매로 사용", message: "구독과 광고 없이 이용해요. 추가 결제는 필요하지 않아요.")
                    }
                    .cardSurface()
                    VStack(alignment: .leading, spacing: 10) {
                        Text("변환할 때 알아두세요")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                        Text("용량은 1 KB = 1,000 바이트로 계산해요. 설정한 용량을 맞추기 위해 화질이나 사진 크기가 줄어들 수 있어요. PNG의 투명한 부분은 흰색으로 바뀌며, 움직이는 사진은 정지된 JPG로 저장돼요.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("임시 파일과 저장 권한")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                        Text("작업 중에는 앱 안에 임시 파일을 만들어요. ‘비우기’를 누르면 작업용 파일을 지워요. 사진 앱에 저장할 때만 사진 추가 권한을 요청해요. 권한을 허용하지 않아도 파일 공유를 이용할 수 있어요.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        Button {
                            showsPrivacyPolicy = true
                        } label: {
                            Label("개인정보처리방침", systemImage: "hand.raised")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 9)
                        }
                        if let mailURL = URL(string: "mailto:sp040122@gmail.com") {
                            Link(destination: mailURL) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Label("지원 문의", systemImage: "envelope")
                                    Text("sp040122@gmail.com")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 9)
                            }
                        }
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(AppTheme.teal)
                    .cardSurface()
                    Text("딱사진 1.0")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                }
                .padding(24)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .navigationTitle("딱사진 소개")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") { dismiss() }
                }
            }
            .sheet(isPresented: $showsPrivacyPolicy) {
                PrivacyPolicyView()
            }
        }
        .tint(AppTheme.teal)
        .presentationDragIndicator(.visible)
    }

    private func aboutItem(icon: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(AppTheme.teal)
                .frame(width: 25)
                .padding(.top, 2)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
