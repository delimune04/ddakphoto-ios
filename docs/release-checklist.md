# 딱사진 출시 체크리스트

상태: GitHub macOS에서 실제 iOS 시뮬레이터 빌드·XCTest·앱 스크린샷 캡처 완료. 배포 서명·TestFlight 실기기 검증·App Store 업로드·심사 제출은 아직 완료하지 않았습니다. 등록 문구는 실제 계정 정보와 대조하고 입력해야 합니다.

[성공한 검증 실행 37112234981](https://github.com/delimune04/ddakphoto-ios/actions/runs/37112234981)은 commit `41a2456829a15d546ffb90a047dc4de8a39031b9` 기준입니다. Xcode 26.6 / iOS 26.5 / iPhone 17 Pro Max에서 HEIC 입력을 포함한 XCTest 10개가 통과했고 실패는 0개입니다. 실제 앱 화면 `1320 × 2868` 캡처도 확인했습니다. 개인 Mac 없이 진행하는 방법은 [클라우드 출시 경로](cloud-build.md)에 정리했습니다.

## 1. macOS 시뮬레이터 및 iPhone 검증

- [x] GitHub macOS 실행 환경에서 Xcode 26.6과 iOS 26.5 시뮬레이터 런타임을 사용했습니다.
- [x] `DdakPhoto.xcodeproj`의 iPhone 시뮬레이터 빌드를 완료했습니다. 배포 대상은 iOS 17 이상, 한국어 UI입니다.
- [x] `./scripts/verify-ios.sh`로 실제 시뮬레이터 빌드·XCTest 10개·앱 화면 캡처를 완료했습니다.
- [ ] iPhone에서 사진 선택, JPEG·HEIC 입력, 여러 장 변환, 목표 용량·크기, 가로/세로 회전, 저장·공유를 확인합니다.
- [ ] 사진 저장 권한 허용·거부, 선택 취소, 읽기 실패, 재선택, 결과 지우기, 재실행을 확인합니다.
- [ ] 원본 유지, 생성 파일의 EXIF·GPS 제거, 캐시 정리를 확인합니다.
- [ ] 작은 용량 목표에서 품질·해상도가 낮아지는 안내가 이해되는지 확인합니다.
- [ ] 투명 이미지와 움직이는 사진은 JPEG 정지 이미지로 변환되는지 확인합니다.
- [ ] 동적 글자 크기와 VoiceOver로 핵심 흐름을 확인합니다. 검증한 기능만 Accessibility Nutrition Label에 기재합니다.

## 2. 계정·앱 등록

- [x] 사용자가 Apple Developer Program 가입 계정이 있음을 확인했습니다. 현재 작업 환경에는 그 계정이 연결되어 있지 않습니다.
- [ ] Apple Developer 계정에서 App ID를 등록하고 Bundle ID 사용 가능 여부를 확인합니다. 후보는 `app.ddakphoto.ios`입니다.
- [ ] Xcode의 Signing & Capabilities에서 실제 Team을 선택합니다. Bundle ID를 바꿨다면 앱 프로젝트와 App Store Connect를 함께 맞춥니다.
- [ ] App Store Connect에서 앱을 생성합니다. 주 언어 한국어, iOS, 고유 SKU, 동일 Bundle ID를 지정합니다. 앱 이름의 사용 가능 여부를 확인합니다.
- [ ] 유료 판매를 위한 Paid Apps Agreement의 활성 상태와 실제 세금·은행 정보를 확인합니다. 약관 동의와 은행·세금 정보는 계정 소유자가 처리해야 합니다.
- [ ] 한국에 소재한 개인·조직에 요구되는 한국 규정 연락처/식별 정보를 완료합니다. 필요 정보는 계정 유형 및 App Store Connect 안내에 따릅니다.

## 3. 공개 지원·정책·상품 페이지

- [x] 공개 지원 이메일 **sp040122@gmail.com** 사용을 허용받아 지원·정책 페이지에 반영했습니다. 심사 담당자 이름·전화번호와 법적 권리자 표기는 별도 확인이 필요합니다.
- [x] `web/`을 공개 HTTPS로 호스팅했습니다. [지원](https://ddakphoto-support.sp040122.chatgpt.site/support.html), [개인정보처리방침](https://ddakphoto-support.sp040122.chatgpt.site/privacy.html).
- [x] 소개·지원·정책 공개 URL이 로그인 없는 브라우저 요청에서 HTTP 200으로 제공되는 것을 확인했습니다. 지원·정책 페이지의 실제 이메일도 확인했습니다.
- [ ] 공개한 지원 URL와 개인정보처리방침 URL를 실제 iPhone의 Safari에서도 열어 확인합니다.
- [x] `release/metadata/app.json`의 `support_url`, `privacy_policy_url`에 실제 공개 URL을 반영했습니다.
- [ ] `copyright`, `review_contact`를 실제 계정·담당자 정보로 작성합니다.
- [ ] `release/metadata/ko/`를 기본 문구로 입력합니다. 영어 문구는 한국어 UI임을 알린 뒤 필요할 때 추가합니다.
- [x] 실제 iPhone 시뮬레이터 앱 실행 화면에서 스크린샷을 캡처했습니다.
- [x] 캡처한 화면이 iPhone 6.9인치 허용 규격인 `1320 × 2868`임을 확인했습니다.
- [ ] 제출할 스크린샷의 내용·샘플 사진 권리를 최종 확인하고 App Store Connect에 등록합니다.
- [ ] 스크린샷은 1~10장, PNG/JPG, 투명도 없음. iPhone 전용 앱이므로 iPad 상품 페이지 화면을 요구한다고 가정하지 않습니다.
- [ ] 앱 아이콘을 최종 archive에서 확인합니다. 플랫폼의 요구 크기 및 투명도 조건을 만족해야 합니다.
- [ ] 한국 기준 가격 목표 2,200원을 Pricing and Availability에서 확인하고 설정합니다. 다른 국가 가격, 출시 국가, 세금 범주를 확인합니다.
- [ ] 초기 출시 지역은 한국을 기본 후보로 검토합니다. EU 등 추가 지역을 선택하면 해당 계정의 규정 정보도 완료합니다.
- [ ] Apple silicon Mac 및 Apple Vision Pro 자동 제공 여부를 확인합니다. 검증하지 않은 환경은 최초 출시 범위에서 제외할 수 있습니다.

## 4. 개인정보·등급·심사 정보

- [ ] 현재 구현과 일치하면 App Privacy에서 “No, we do not collect data from this app”를 저장·게시합니다.
- [ ] 최종 archive의 privacy manifest와 required reason API 보고서를 확인합니다.
- [ ] 콘텐츠 등급 설문을 아래 사실에 따라 답하고 Apple이 계산한 등급을 기록합니다. “4+”를 확정값으로 미리 입력하지 않습니다.
- [ ] 실제 권리자와 제3자 콘텐츠 권한을 확인합니다. 사용자가 자신의 사진을 로컬 변환하는 기능과 앱이 배포하는 콘텐츠를 구분합니다.
- [ ] 별도 암호화 구현이 없는 현재 앱에 맞게 export compliance 질문에 답합니다. 소스와 최종 바이너리 확인 뒤 관련 Info.plist 값을 검토합니다.
- [ ] App Review Contact에 실제 이름, 이메일, 국제 형식 전화번호를 입력합니다.
- [ ] Sign-in required를 선택하지 않습니다. 데모 계정은 필요 없습니다.
- [ ] `review_information/review_notes.txt`를 최종 바이너리와 대조하고 마지막 초안 안내 문장을 제거한 뒤 입력합니다.
- [ ] 첫 출시 release mode는 Manual 후보입니다. 심사 통과 후 최종 가격과 상품 페이지를 확인하고 출시합니다.

### 콘텐츠 등급 답변 근거

현재 앱은 로컬 사진 변환 도구입니다. **부모 통제·연령 확인·앱 내 자유 웹 탐색·공개 UGC 피드·소셜 기능·채팅·광고·의료/웰니스 안내·도박·경품 대회·루트박스가 없습니다.** 앱이 제공하는 성인·폭력·공포·약물 등의 콘텐츠도 없습니다. 사용자 개인 사진을 선택하는 기능은 Apple 정의의 “broad distribution of content created by users”에 해당하는 공개 UGC 배포 기능이 아닙니다. 외부 앱에 시스템 공유 메뉴로 사본을 전달하는 동작도 앱 내 채팅·소셜 피드는 아닙니다.

App Store Connect에 실제로 나타나는 각 질문을 읽고 위 사실에 맞게 “없음/아니오”를 선택합니다. 공개 웹 브라우저·커뮤니티·광고 등을 나중에 추가하면 다시 평가합니다. Kids 카테고리로 설정하지 않습니다. 지역별·OS별 등급은 Apple 계산 결과를 따릅니다.

## 5. Archive → 업로드 → 심사 제출

- [ ] 실제 Team과 Bundle ID를 설정한 뒤 `./scripts/archive-ios.sh TEAM_ID app.ddakphoto.ios`로 archive를 만들거나 Xcode Product → Archive를 실행합니다.
- [ ] Organizer에서 Validate App 후 Distribute App → App Store Connect로 업로드합니다. 최종 서명과 provisioning은 실제 Apple 계정으로 처리합니다.
- [ ] Apple의 빌드 처리가 완료되면 버전 1.0에 해당 build를 연결합니다. 재업로드가 필요하면 build 번호를 올립니다.
- [ ] 누락된 메타데이터·가격·계정 경고를 해결하고 **Add for Review**를 누릅니다.
- [ ] Draft Submissions/App Review에서 항목을 확인한 뒤 **Submit for Review**를 누릅니다. Add for Review만으로 심사가 시작되지 않습니다.
- [ ] Waiting for Review/In Review 상태를 확인하고 실제 제출 시각·build 번호를 기록합니다. 심사 제출과 승인·출시는 별개입니다.

사용자는 개발자 가입 계정과 iPhone이 있고 Mac은 없습니다. 클라우드 시뮬레이터 빌드·테스트·실제 스크린샷과 공개 지원·정책 URL은 준비됐습니다. 현재 해결이 필요한 항목: **Apple 계정 연결·서명·업로드, TestFlight 실기기 검증, 심사 연락처·권리자 정보와 상품 페이지 등록, 유료 계약·정산 정보**. 실제 제출 전에는 제출 완료라고 표시할 수 없습니다.

공식 출처와 확인 내용은 [제출 요구사항](submission-requirements.md)에 정리했습니다.
