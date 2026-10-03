# 딱사진

사진을 원하는 최대 용량과 크기에 맞춰 JPG로 만드는 iPhone 앱입니다. iOS 17 이상, 한국어 UI, 한 번 구매하는 유료 앱을 목표로 합니다. 한국 가격 목표는 2,200원이며 실제 가격 선택은 App Store Connect에서 확인해야 합니다.

사용자는 개발자 가입 계정과 iPhone이 있고 Mac은 없습니다. [공개 소스 저장소](https://github.com/delimune04/ddakphoto-ios)의 GitHub macOS 실행 환경에서 iOS 빌드·테스트·실제 앱 화면 캡처를 완료했습니다. [iPhone만 있을 때의 클라우드 출시 경로](docs/cloud-build.md)에 Apple API 키와 GitHub secrets 설정부터 TestFlight·심사 제출까지 정리했습니다.

공개 페이지: [지원](https://ddakphoto-support.sp040122.chatgpt.site/support.html) · [개인정보처리방침](https://ddakphoto-support.sp040122.chatgpt.site/privacy.html). 지원 이메일은 `sp040122@gmail.com`입니다.

## 기능

- 최대 20장의 사진을 시스템 사진 선택기로 가져오기
- 최대 용량 200/500/1,000KB 또는 사용자 지정 10~20,000KB
- 긴 변 길이 자동/1,080/1,920픽셀 또는 사용자 지정 128~8,192픽셀
- 기기 안에서 JPEG 변환, 결과 용량·크기 확인, 한 장 또는 여러 장 저장·공유
- 원본 유지, 결과 파일에 원본 EXIF·위치를 복사하지 않음
- 광고·구독·추가 인앱 결제·계정·서버 없이 동작

1KB는 1,000바이트입니다. 작은 용량 제한은 화질이나 해상도를 낮출 수 있습니다. JPEG는 투명도를 지원하지 않으며 움직이는 입력은 정지 이미지로 변환됩니다. iCloud에만 있는 원본은 Apple 사진 서비스의 다운로드가 필요할 수 있습니다.

## Mac에서 실행

App Store에서 현재 지원하는 Xcode와 iOS 시뮬레이터 런타임이 설치된 Mac이 필요합니다. 2026-10-03 공식 문서 확인 기준 iOS 빌드는 Xcode 26 이상이며 최신 Xcode 27을 권장합니다.

```sh
open DdakPhoto.xcodeproj
./scripts/verify-ios.sh
```

Xcode 프로젝트를 생성한 상태로 보관하며 XcodeGen 설치는 필요하지 않습니다. 시뮬레이터 빌드는 Apple 계정 없이 할 수 있으며, 실기기 실행과 배포 서명은 실제 Team이 필요합니다. 후보 Bundle ID는 `app.ddakphoto.ios`이며 사용 가능 여부는 Apple 계정에서 확인해야 합니다.

`verify-ios.sh`로 실제 GitHub macOS 검증을 완료했습니다. [성공한 실행 37112234981](https://github.com/delimune04/ddakphoto-ios/actions/runs/37112234981), commit `41a2456829a15d546ffb90a047dc4de8a39031b9` 기준입니다.

- Xcode 26.6, iOS 26.5, iPhone 17 Pro Max 시뮬레이터 빌드 성공
- HEIC 입력을 포함한 XCTest 10개 통과, 실패 0개
- 실제 앱 스크린샷 `1320 × 2868` 캡처 확인

실행의 `ddakphoto-ios-verification` artifact에서 로그·XCTest 결과·스크린샷을 확인할 수 있습니다. 배포 서명, TestFlight 실기기 검증과 App Store 업로드는 아직 완료하지 않았습니다.

## App Store 제출 준비

```sh
./scripts/archive-ios.sh TEAM_ID app.ddakphoto.ios
```

`TEAM_ID`를 실제 개발자 Team ID로 바꿉니다. 실제 계정으로 archive를 서명한 뒤 Xcode Organizer에서 Validate App → Distribute App → App Store Connect로 진행합니다. 필요하다면 Xcode Product → Archive를 사용할 수 있습니다.

- [출시 체크리스트](docs/release-checklist.md): Mac 검증부터 실제 심사 제출까지
- [한국어·영어 등록 문구](release/metadata/README.md): 상품 페이지와 심사 메모 초안
- [개인정보 공개안](docs/privacy-disclosure.md): Data Not Collected 판단 및 검증 항목
- [Apple 공식 요구사항](docs/submission-requirements.md): 2026-10-03 확인 근거
- [지원·개인정보 웹페이지](web/README.md): 공개 이메일을 반영한 정적 페이지

macOS 검증용 workflow와 API 키를 사용하는 signed IPA·App Store Connect 업로드용 workflow를 모두 포함했습니다. 업로드 workflow는 아직 실제 계정으로 실행하지 않았습니다.

남은 제출 요건은 **Apple 계정 서명·업로드, TestFlight 실기기 검증, 유료 계약·정산 정보와 상품 페이지·심사 정보 등록**입니다. 법적 권리자와 심사 담당자 이름·전화번호는 실제 계정 정보로 확인해야 합니다. 심사 제출은 아직 하지 않았습니다.
