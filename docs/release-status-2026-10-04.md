# 딱사진 출시 준비 재점검

확인: 2026-10-04 UTC. 아래는 관찰된 상태입니다. 앱 레코드 등록은 완료됐지만 서명·TestFlight 업로드·심사 제출은 아직 완료되지 않았습니다.

## 검증한 상태

- 공개 저장소의 main 최신 커밋: `6a9cc2f07c4e8513bf798a78963bb691cc315a72`
- [iOS 검증 37114244694](https://github.com/delimune04/ddakphoto-ios/actions/runs/37114244694): 성공. Xcode 26.6 / iOS 26.5에서 XCTest 10개 통과(실패 0), 서명 없는 Release archive 성공
- 같은 실행의 `ddakphoto-ios-verification` 산출물에서 실제 화면 2장을 복원해 직접 확인: 1320 × 2868 RGB JPEG. 아이콘은 1024 × 1024 RGB PNG
- 05:07 UTC에 Apple Developer의 `app.ddakphoto.ios` App ID 및 [딱사진 App Store Connect 앱 레코드](https://appstoreconnect.apple.com/apps/6818943176/distribution) 생성 완료를 확인. 앱 ID `6818943176`, SKU `DDAKPHOTO_IOS_001`. 서명 키·인증서는 생성하지 않음
- 저장소에 App Store Connect upload 워크플로 실행 기록은 아직 없음
- 새로 추가한 로컬 메타데이터 검사와 21개 회귀테스트는 통과. 새 변경에 대한 macOS CI는 아직 실행하지 않음
- 개인 Mac 없이 GitHub macOS를 이용하는 기존 빌드 경로는 유지 가능

## 등록한 앱 정체성

- 앱 이름: `딱사진 - 사진 용량 줄이기` (기존 한국어 메타데이터)
- Bundle ID: `app.ddakphoto.ios` (등록 완료)
- SKU: `DDAKPHOTO_IOS_001` (등록 완료, 생성 후 변경 불가)
- iOS / iPhone / 기본 언어 한국어 / 버전 1.0
- 지원·정책 URL과 한국어·영어 문구는 `release/metadata/`에 준비
- 한국 가격 2,200원은 제안이며 **사용자 승인 및 App Store Connect 실제 선택값 미확인**

## 다음 단계와 구분

1. 딱사진 App ID 및 App Store Connect 앱 레코드를 등록했습니다. 다음 목표는 내부 TestFlight이며 심사 제출은 보류합니다.
2. 딱사진 저장소에서 쓸 서명 경로를 결정합니다. 다른 앱의 비밀키를 자동으로 가져오거나 재사용하지 않습니다. 새 API 키·인증서 또는 지속 접근 권한을 만드는 경우 별도로 확인받습니다. 비밀키는 사용자가 승인된 보안 입력 경로로 직접 설정하며 채팅·공개 저장소에 넣지 않습니다.
3. 정확한 커밋의 iOS 검증을 통과한 뒤, 승인된 범위에서 signed IPA를 빌드하고 TestFlight에 올립니다. TestFlight 업로드 성공과 Apple 처리 완료를 각각 확인합니다.
4. 실제 iPhone에서 가져오기·변환·저장·공유와 실패/취소·권한 거부·재선택 흐름을 검증합니다.
5. 공개 판매 전에 실제 심사 연락처·권리자·등급·가격·판매 지역 및 유료 계약/정산 상태를 확인합니다. 연락처·정산 정보는 공개 소스에 기록하지 않습니다.
6. 심사 제출과 공개 출시는 별도로 승인된 범위에서 진행합니다.

## 로컬 검사 사용

```sh
python3 -m unittest discover -s scripts -p 'test_*.py'
python3 scripts/generate-project.py --check
python3 scripts/verify-metadata.py
python3 scripts/verify-metadata.py --submission --json
```

마지막 명령은 현재 미확인 필드를 오류로 보고하고 1을 반환해야 합니다. 이는 잘못된 제출 가능 판정을 막기 위한 동작입니다. 초안 검사 통과가 출시 준비 완료를 뜻하지 않습니다.

참고: [Apple 앱 정보 필드](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/), [버전 정보 한도](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/), [스크린샷 규격](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)을 2026-10-04에 다시 확인했습니다.
