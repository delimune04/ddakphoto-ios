# 개인정보 공개안

배포 바이너리와 최종 대조해야 하는 초안입니다. 이 문서는 현재 설계대로 외부 SDK, 분석, 광고, 계정, 앱의 네트워크 통신이 없는 버전에만 적용합니다.

## App Store Connect

App Privacy → Get Started에서 **“No, we do not collect data from this app”**를 선택합니다. 상품 페이지 표시는 **Data Not Collected / 데이터 수집 안 함**입니다. Apple은 기기 내에서만 처리되고 서버로 전송되지 않는 데이터를 이 질문의 “수집”에 포함하지 않습니다.

| 처리 내용 | 실제 동작 | 공개 판단 |
|---|---|---|
| 사용자가 선택한 사진 | 시스템 Photos picker로 선택한 입력만 가져와 기기 안에서 변환 | 개발자에게 전송하지 않으므로 수집 안 함 |
| 원본 EXIF·위치 | 입력 처리에 포함될 수 있지만 새 JPEG에 복사하지 않음 | 개발자에게 전송하지 않음 |
| 작업용 사진 사본·변환 결과 | 앱의 임시 저장 공간에 보관; 결과 지우기 및 다음 실행 시 정리 | 기기 내 임시 처리 |
| 사진 저장 | 사용자가 요청하면 사진 보관함 추가 전용 권한 요청 후 새 파일 추가 | 기존 사진을 수정·삭제하지 않음 |
| 공유 | 사용자가 시스템 공유 메뉴에서 선택한 대상에 사본 전달 | 사용자가 선택한 대상의 정책 적용 |
| 구입·결제 | App Store가 처리; 앱에 결제 폼·계정·구매 이력 수집 코드 없음 | 개발자가 앱에서 결제 정보를 수집하지 않음 |
| 분석·광고·추적 | 관련 코드 및 외부 SDK 없음 | 수집·추적 안 함 |

권한 설명과 정책에는 “사진 저장”을 위한 **추가 전용 권한**임을 표시합니다. 전체 사진 보관함 읽기 권한이나 위치 권한을 요구하지 않습니다. iCloud에만 있는 원본은 Apple 사진 서비스에서 다운로드가 필요할 수 있으므로 “모든 상황에서 네트워크를 전혀 쓰지 않는다”고 설명하지 않습니다.

결과를 지워도 사용자가 사진 보관함에 저장하거나 다른 앱으로 공유한 사본은 남습니다. 앱 삭제는 앱 데이터 정리 방법이며, 사용자가 별도로 저장·공유한 사본까지 지우지는 않습니다.

## 공개 정책과 지원

공개한 정적 페이지는 [개인정보처리방침](https://ddakphoto-support.sp040122.chatgpt.site/privacy.html), [지원](https://ddakphoto-support.sp040122.chatgpt.site/support.html)입니다. 소스는 `web/privacy.html`, `web/support.html`입니다. 사용자가 공개를 허용한 지원 이메일은 **sp040122@gmail.com**입니다. App Store Connect와 앱 내 정책·지원 링크에 같은 주소를 연결합니다. 정책 URL은 데이터 수집이 없는 앱에도 필수입니다.

사용자가 별도로 문의를 보내면 이메일 주소와 문의 내용이 문의 확인·답변에 사용됩니다. 이메일 서비스의 보관·처리에는 해당 제공자의 정책이 적용됩니다. 앱 안에 문의 정보를 자동 전송하는 기능은 없습니다. 이를 앱의 자동 데이터 수집과 구분합니다.

웹 호스팅 제공자가 처리하는 접속 로그는 호스팅 설정과 해당 제공자 정책을 확인해야 합니다. 앱의 데이터 수집 안 함 표기를 근거로 지원 웹사이트의 로그가 없다고 주장하지 않습니다.

## 배포 직전 확인

- 최종 앱에 URLSession/네트워크 요청, 분석·광고 SDK, Crash SDK, 계정, 서버 업로드가 추가되지 않았는지 확인합니다.
- 생성한 JPEG를 실제로 열어 EXIF·GPS가 제거됐는지 확인합니다.
- 작업용 입력 사본·결과 파일 정리와 저장/공유 사본의 보존 동작을 실기기에서 확인합니다.
- PrivacyInfo.xcprivacy, 사용 중인 required reason API와 최종 archive Privacy Report를 검토합니다. 개인정보 라벨과 privacy manifest는 서로 다른 요구사항입니다.
- 지원 링크를 누를 때만 외부 브라우저가 열리는지 확인합니다.

공식 근거: [App privacy details](https://developer.apple.com/app-store/app-privacy-details/), [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/).
