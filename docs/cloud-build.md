# iPhone만 있을 때의 출시 경로

사용자의 Apple Developer Program 가입 계정과 iPhone을 사용하고, iOS build는 GitHub Actions의 **macOS 실행 환경**에서 진행하는 경로입니다. 개인 Mac을 새로 구매할 필요는 없지만 Apple SDK를 실행하는 macOS 환경은 필요합니다.

사용자가 생성한 [공개 소스 저장소](https://github.com/delimune04/ddakphoto-ios)로 진행합니다. 소스·프로젝트와 검증·업로드 workflow를 준비했고, GitHub macOS에서 실제 시뮬레이터 빌드·테스트·스크린샷 캡처를 완료했습니다. Apple 인증 정보는 GitHub encrypted secrets에 직접 설정합니다.

## 1. 서명 없이 먼저 실행 검증

완료된 검증: [실행 37112234981](https://github.com/delimune04/ddakphoto-ios/actions/runs/37112234981), commit `41a2456829a15d546ffb90a047dc4de8a39031b9`.

- Xcode 26.6 / iOS 26.5 / iPhone 17 Pro Max에서 시뮬레이터 빌드 성공
- HEIC 입력을 포함한 XCTest 10개 통과, 실패 0개
- 실제 앱 스크린샷 `1320 × 2868` 캡처 확인

`.github/workflows/ios-verify.yml`은 Apple 서명 키 없이 이 검증을 수행합니다. 성공한 실행의 `ddakphoto-ios-verification` artifact에서 `.xcresult`, 로그와 `release/screenshots`를 확인합니다. 코드가 바뀌면 그 commit의 verification을 다시 통과해야 업로드할 수 있습니다.

검증용 workflow의 성공은 앱 출시나 App Store 업로드를 뜻하지 않습니다. 실행 실패는 로그의 구체적인 오류를 고친 뒤 다시 확인해야 합니다.

## 2. Apple 계정으로 서명하고 TestFlight 배포

검증 후에는 실제 Team ID와 등록한 Bundle ID, 배포 인증서·provisioning 또는 Apple 자동 서명에 필요한 접근 권한을 연결해야 합니다. **현재 검증용 workflow는 배포 서명과 업로드를 하지 않습니다.**

서명·업로드용 `.github/workflows/ios-upload.yml`도 준비했습니다. 실제 계정으로 실행한 적은 없으며 자동 서명에 필요한 인증서·provisioning 접근 권한이 갖춰져야 합니다. 같은 commit의 iOS verification이 성공해야 업로드 workflow가 시작됩니다.

GitHub 저장소의 Settings → Secrets and variables → Actions에 다음 encrypted secrets를 직접 설정합니다. 비밀번호와 인증 코드를 보내거나 키 원문을 채팅에 붙여넣지 않습니다.

### iPhone Safari에서 팀 API 키 만들기

1. Safari에서 [App Store Connect](https://appstoreconnect.apple.com/)에 개발자 계정으로 로그인합니다. 메뉴가 보이지 않으면 Safari의 **데스크탑 웹사이트 요청**을 사용합니다.
2. **Users and Access → Integrations → App Store Connect API → Team Keys**를 엽니다. 이 workflow의 자동 서명에는 팀 API 키를 사용합니다. 개인 API 키는 provisioning API에 접근할 수 없습니다.
3. 처음 사용하는 계정에 **Request Access**가 나타나면 Account Holder가 API 접근 신청을 먼저 완료해야 합니다.
4. Account Holder 또는 Admin 계정으로 **Generate API Key** 또는 `+`를 눌러 이름을 입력하고 키 역할을 **Admin**으로 선택합니다. 자동 서명에 필요한 배포 인증서 생성은 Account Holder/Admin 권한이 필요하며, 이 workflow가 인증서와 provisioning profile을 생성·갱신할 수 있도록 Admin 역할의 팀 키를 준비합니다.
5. 생성한 키의 **Key ID**와 같은 화면의 **Issuer ID**를 확인합니다.
6. **Download API Key**로 `.p8` 파일을 받아 iPhone 파일 앱에 보관합니다. 키 파일은 생성 후 한 번만 다운로드할 수 있으므로 보관한 파일을 사용합니다. 파일이나 키 내용은 채팅에 보내지 않습니다.
7. [Apple Developer 계정](https://developer.apple.com/account/)의 **Membership details**에서 10자리 **Team ID**를 확인합니다. Key ID나 Issuer ID와 다른 값입니다.

공식 안내: [App Store Connect API](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api/), [API 키 만들기](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api), [인증서와 역할](https://developer.apple.com/help/account/certificates/certificates-overview/).

### GitHub secrets 네 개 설정하기

iPhone Safari에서 [저장소](https://github.com/delimune04/ddakphoto-ios)를 열고 **Settings → Secrets and variables → Actions → New repository secret**으로 이동합니다. 아래 순서로 네 개를 각각 저장합니다.

| 순서 | Secret 이름 | 입력할 값 |
|---|---|---|
| 1 | `APPLE_TEAM_ID` | Apple Developer Membership details의 10자리 Team ID |
| 2 | `ASC_KEY_ID` | 방금 만든 팀 API 키의 Key ID |
| 3 | `ASC_ISSUER_ID` | App Store Connect 팀 API 키 화면의 Issuer ID |
| 4 | `ASC_PRIVATE_KEY` | 다운로드한 `.p8` 파일의 **텍스트 내용 전체** |

`ASC_PRIVATE_KEY`에는 파일 이름이나 경로가 아닌 `-----BEGIN PRIVATE KEY-----`부터 `-----END PRIVATE KEY-----`까지의 전체 내용과 줄바꿈을 넣습니다. Base64로 변환하지 않습니다. 키는 GitHub secret에 직접 저장하고, 공개 소스 저장소·이슈·채팅에는 붙여넣지 않습니다.

#### iPhone에서 `.p8` 내용 복사

단축어 앱에서 새 단축어를 만들고 **파일 선택 → 입력에서 텍스트 가져오기 → 클립보드에 복사**를 연결합니다. 실행해서 다운로드한 `.p8`를 선택한 뒤 GitHub의 `ASC_PRIVATE_KEY` Value에 바로 붙여넣습니다. 첫 줄과 마지막 줄을 포함한 원문 전체가 유지됐는지 확인합니다.

텍스트로 인식되지 않으면 원본 `.p8`는 그대로 보관하고 **복제본만 `.txt`로 바꿔** 선택할 수 있습니다. 이 단축어 흐름은 현재 실기기에서 실행 검증하지 않았습니다. Apple의 [콘텐츠 그래프 안내](https://support.apple.com/guide/shortcuts/the-content-graph-engine-apd4618db957/ios)를 참고하세요.

Apple Developer에서 Bundle ID를 등록하고 App Store Connect에서 그 Bundle ID의 앱 기록을 먼저 만듭니다. Actions → App Store Connect upload → Run workflow에서 등록한 Bundle ID를 입력합니다. 이 작업은 서명 전 archive와 배포 서명된 IPA를 만들고 App Store Connect에 빌드를 올립니다. 키는 runner의 임시 공간에만 생성하며 종료 시 지웁니다. 심사 제출은 다음 단계입니다.

**실제 Apple 계정으로 서명·업로드 workflow를 실행한 적은 아직 없습니다.** 키와 앱 등록을 완료한 뒤 실행 결과를 확인해야 합니다.

Mac 실행 환경에서 archive 스크립트는 다음 인터페이스를 사용합니다.

```sh
./scripts/archive-ios.sh TEAM_ID app.ddakphoto.ios
```

`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH`가 모두 제공되면 스크립트가 Xcode 인증 키 옵션을 사용합니다. 이는 실제 계정의 키·권한과 provisioning이 갖춰져야 동작하며 키 이름만 설정해서 서명이 완성되는 것은 아닙니다. Mac의 Xcode에 로그인한 계정으로 진행하는 방법도 있습니다. IPA 출력 위치는 `build/release/exports/`입니다.

클라우드 업로드 workflow는 `DDAKPHOTO_UNSIGNED_ARCHIVE=1`로 Release archive를 먼저 만들고, API 키를 사용하는 `exportArchive`에서 배포 서명을 요청합니다. 개발용 기기 등록 없이 App Store 배포 서명을 진행하기 위한 경로이며, 실제 계정의 배포 권한과 export 성공은 업로드 실행에서 확인해야 합니다. 로컬 스크립트의 기본값은 기존 Xcode 서명 방식입니다. 검증 workflow에서도 서명 없는 Release archive 빌드를 확인하지만 배포 서명 성공을 뜻하지는 않습니다. Apple의 [클라우드 서명 설명](https://developer.apple.com/videos/play/wwdc2021/10204/)을 참고하세요.

업로드한 빌드가 처리되면 App Store Connect에서 자신의 계정을 내부 TestFlight 테스터로 지정합니다. TestFlight로 자신의 iPhone에서 설치해 사진 가져오기·변환·저장·공유, 권한 거부, 원본 유지, EXIF·위치 제거를 확인합니다.

## 3. App Store 심사 제출

iPhone 브라우저의 App Store Connect에서 유료 계약·세금·은행 정보, 심사 연락처, 가격, 실제 스크린샷과 등록 문구를 완료합니다. 화면이 불편하면 Safari의 데스크탑 웹사이트 요청을 사용할 수 있습니다. 계정 화면에서 요구하는 실제 정보를 따라 진행합니다.

공개 지원·정책 URL은 이미 준비됐습니다.

- https://ddakphoto-support.sp040122.chatgpt.site/support.html
- https://ddakphoto-support.sp040122.chatgpt.site/privacy.html

최종 build를 버전 1.0에 연결하고 Add for Review → Submit for Review를 실행해야 실제 심사 제출입니다. 실제 계정 작업과 제출은 아직 완료되지 않았습니다. 상세 항목은 [출시 체크리스트](release-checklist.md)를 참고하세요.
