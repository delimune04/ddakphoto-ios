# Apple 공식 제출 요구사항 확인

확인일: **2026-10-03 UTC**. 아래 Apple 공개 웹 문서를 직접 조회했습니다. 계정 로그인 화면·계약 상태·가격 선택지는 확인하지 않았습니다. 변경 가능한 요구사항은 실제 업로드 직전에 재확인합니다.

| 항목 | 확인 내용 | 공식 문서 |
|---|---|---|
| iOS 빌드 도구 | Upload builds의 표는 iOS 앱을 Xcode 26 이상으로 빌드해야 한다고 안내합니다. 별도로 앱 제출 페이지는 최신 Xcode 27로 빌드·테스트를 권장합니다. | [Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/), [Submitting](https://developer.apple.com/app-store/submitting/) |
| 미래 SDK 변경 | Submitting은 **2027년 4월부터** iOS/iPadOS 27 SDK 이상, iOS 15 이상 target을 요구한다고 안내합니다. 현재 날짜의 요구사항과 구분해야 합니다. | [Submitting](https://developer.apple.com/app-store/submitting/) |
| 배포 최소 OS | Upcoming Requirements에서 **2026-09-09부터** 업로드하는 iOS/iPadOS 앱은 iOS 13 이상을 target으로 해야 한다고 안내합니다. 이 앱의 iOS 17 배포 대상은 그 이상입니다. | [Upcoming requirements](https://developer.apple.com/news/upcoming-requirements/) |
| 유료 앱 | Account Holder가 Paid Apps Agreement에 동의해야 유료 앱을 판매할 수 있습니다. 유료 제출/업데이트를 위해 계약이 활성 상태여야 합니다. 동의는 취소할 수 없는 계정 행위입니다. | [Sign and update agreements](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/) |
| 가격 | 제출 전에 가격을 정해야 합니다. 기준 국가의 가격과 다른 국가의 환산 가격을 확인합니다. 2,200원이라는 실제 선택값은 로그인된 계정에서 확인해야 합니다. | [Set a price](https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price/) |
| 지원 URL | 지원 URL은 필수이며 사용자가 문의할 수 있는 실제 연락처로 이어져야 합니다. 저작권 표기와 심사 담당자 이름·이메일·전화번호도 필수 정보입니다. | [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/) |
| 개인정보 URL | 모든 앱에 공개 개인정보처리방침 URL이 필요합니다. 데이터 수집이 없으면 App Privacy의 “No, we do not collect data from this app”를 선택합니다. | [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/) |
| 기기 내 처리 | Apple은 기기 내에서만 처리되고 서버로 전송되지 않는 데이터를 App Privacy 질문의 수집에 포함하지 않는다고 설명합니다. 외부 SDK의 처리도 함께 고려해야 합니다. | [App privacy details](https://developer.apple.com/app-store/app-privacy-details/) |
| 등록 문구 | 이름·부제 각각 30자, 설명 4,000자, 홍보 문구 170자, 키워드 100바이트, review notes 4,000바이트. 첫 버전에는 What's New 필드가 없습니다. | [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/), [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/) |
| 스크린샷 | 1~10장, JPEG/JPG/PNG, alpha/transparency 없음. iPhone 6.9인치 허용 세로 크기는 1260×2736, 1290×2796, 1320×2868입니다. 6.9인치 자산이 없으면 6.5인치 자산이 요구됩니다. iPad 실행 지원 앱은 13인치 iPad 자산이 필요합니다. | [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) |
| 등급 | 설문에 실제 기능·콘텐츠의 존재/빈도를 답하면 Apple이 지역·OS별 적정 등급을 생성합니다. 최신 표에는 4+/9+/13+/16+/18+ 등이 있으며 이전 OS 등급과 다를 수 있습니다. UGC는 광범위한 사용자 콘텐츠 배포를 포함하는 기능으로 정의합니다. | [Age ratings values and definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/) |
| 한국 계정 규정 | 한국 소재 개발자에게 계정 유형에 따른 연락처/식별 정보가 요구됩니다. 조직·개인 구분과 BRN 처리 등은 실제 계정의 Korean Law/세금 화면에 따릅니다. 임의로 번호나 법적 정보를 생성하면 안 됩니다. | [Manage Korea compliance information](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-korea-compliance-information/) |
| 암호화 | App Store Connect의 질문으로 문서 필요 여부를 판단합니다. 문서가 필요 없는 앱은 Info.plist로 해당 사실을 표시할 수 있습니다. 최종 구현 기준으로 답해야 합니다. | [Encryption documentation](https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation/) |
| 제출 | 필수 메타데이터와 build를 준비하고 Add for Review 후 **Submit for Review**를 해야 실제 심사로 전송됩니다. 필요한 역할은 Account Holder/Admin/App Manager입니다. | [Submit an app](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/) |
| 기능 완성도 | 실제 기기 실행 검증, 정확한 상품 페이지, 접근 가능한 정책·연락처를 준비하고 App Review Guidelines와 최종 앱을 대조합니다. 승인 여부는 Apple 심사 결과입니다. | [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) |

이 확인은 **문서 조사**이며 Apple 계정 등록·계약 동의·앱 build·업로드·심사 제출을 실행했다는 의미가 아닙니다.
