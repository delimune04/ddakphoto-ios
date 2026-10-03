# iPhone만 있을 때의 출시 경로

사용자의 Apple Developer Program 가입 계정과 iPhone을 사용하고, iOS build는 GitHub Actions의 **macOS 실행 환경**에서 진행하는 경로입니다. 개인 Mac을 새로 구매할 필요는 없지만 Apple SDK를 실행하는 macOS 환경은 필요합니다.

사용자가 생성한 [공개 소스 저장소](https://github.com/delimune04/ddakphoto-ios)로 진행합니다. 소스·프로젝트와 검증·업로드 workflow를 준비했으며 실제 빌드 결과는 GitHub Actions에서 확인합니다. 공개 저장소에도 Apple 인증 정보는 소스가 아닌 GitHub encrypted secrets에 직접 설정해야 합니다.

## 1. 서명 없이 먼저 실행 검증

1. 연결된 `delimune04/ddakphoto-ios` 저장소를 사용합니다.
2. 이 프로젝트를 저장소에 올립니다. 실제 저장소 URL과 기본 브랜치 이름은 저장소를 연결한 뒤 확인합니다.
3. Actions에서 `.github/workflows/ios-verify.yml`의 실행 상태를 확인합니다. 이 workflow는 Apple 서명 키 없이 시뮬레이터 빌드·XCTest·실제 앱 화면 캡처를 수행합니다.
4. 성공한 실행의 `ddakphoto-ios-verification` artifact에서 `.xcresult`, 로그, `release/screenshots`를 확인합니다. 스크린샷은 실제 iOS 시뮬레이터 앱 화면이어야 합니다.

검증용 workflow의 성공은 앱 출시나 App Store 업로드를 뜻하지 않습니다. 실행 실패는 로그의 구체적인 오류를 고친 뒤 다시 확인해야 합니다.

## 2. Apple 계정으로 서명하고 TestFlight 배포

검증 후에는 실제 Team ID와 등록한 Bundle ID, 배포 인증서·provisioning 또는 Apple 자동 서명에 필요한 접근 권한을 연결해야 합니다. **현재 검증용 workflow는 배포 서명과 업로드를 하지 않습니다.**

서명·업로드용 `.github/workflows/ios-upload.yml`도 준비했습니다. 실제 계정으로 실행한 적은 없으며 자동 서명에 필요한 인증서·provisioning 접근 권한이 갖춰져야 합니다. 같은 commit의 iOS verification이 성공해야 업로드 workflow가 시작됩니다.

GitHub 저장소의 Settings → Secrets and variables → Actions에 다음 encrypted secrets를 직접 설정합니다. 비밀번호와 인증 코드를 보내거나 키 원문을 채팅에 붙여넣지 않습니다.

- `APPLE_TEAM_ID`: Apple Developer 멤버십의 10자리 Team ID
- `ASC_KEY_ID`: App Store Connect에서 생성한 팀 API 키 ID
- `ASC_ISSUER_ID`: 팀 API 키의 Issuer ID
- `ASC_PRIVATE_KEY`: 다운로드한 `.p8` 키 내용. 서명·provisioning 권한이 있는 실제 팀 API 키가 필요합니다.

Apple Developer에서 Bundle ID를 등록하고 App Store Connect에서 그 Bundle ID의 앱 기록을 먼저 만듭니다. Actions → App Store Connect upload → Run workflow에서 등록한 Bundle ID를 입력합니다. 이 작업은 signed archive와 IPA를 만들고 App Store Connect에 빌드를 올립니다. 키는 runner의 임시 공간에만 생성하며 종료 시 지웁니다. 심사 제출은 다음 단계입니다.

Mac 실행 환경에서 archive 스크립트는 다음 인터페이스를 사용합니다.

```sh
./scripts/archive-ios.sh TEAM_ID app.ddakphoto.ios
```

`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH`가 모두 제공되면 스크립트가 Xcode 인증 키 옵션을 사용합니다. 이는 실제 계정의 키·권한과 provisioning이 갖춰져야 동작하며 키 이름만 설정해서 서명이 완성되는 것은 아닙니다. Mac의 Xcode에 로그인한 계정으로 진행하는 방법도 있습니다. IPA 출력 위치는 `build/release/exports/`입니다.

업로드한 빌드가 처리되면 App Store Connect에서 자신의 계정을 내부 TestFlight 테스터로 지정합니다. TestFlight로 자신의 iPhone에서 설치해 사진 가져오기·변환·저장·공유, 권한 거부, 원본 유지, EXIF·위치 제거를 확인합니다.

## 3. App Store 심사 제출

iPhone 브라우저의 App Store Connect에서 유료 계약·세금·은행 정보, 심사 연락처, 가격, 실제 스크린샷과 등록 문구를 완료합니다. 화면이 불편하면 Safari의 데스크탑 웹사이트 요청을 사용할 수 있습니다. 계정 화면에서 요구하는 실제 정보를 따라 진행합니다.

공개 지원·정책 URL은 이미 준비됐습니다.

- https://ddakphoto-support.sp040122.chatgpt.site/support.html
- https://ddakphoto-support.sp040122.chatgpt.site/privacy.html

최종 build를 버전 1.0에 연결하고 Add for Review → Submit for Review를 실행해야 실제 심사 제출입니다. 실제 계정 작업과 제출은 아직 완료되지 않았습니다. 상세 항목은 [출시 체크리스트](release-checklist.md)를 참고하세요.
