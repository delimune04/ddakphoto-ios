# 공개 웹페이지

외부 폰트·스크립트·분석 도구가 없는 정적 HTML/CSS입니다. 다음 주소로 공개했습니다.

- 소개: https://ddakphoto-support.sp040122.chatgpt.site
- 지원: https://ddakphoto-support.sp040122.chatgpt.site/support.html
- 개인정보처리방침: https://ddakphoto-support.sp040122.chatgpt.site/privacy.html

- `index.html`: 앱 소개
- `support.html`: 사용 방법, FAQ, 지원 이메일
- `privacy.html`: 한국어/영어 개인정보처리방침

사용자 허용으로 공개 지원 이메일 `sp040122@gmail.com`을 반영했습니다. 시행일은 2026-10-03입니다.

2026-10-03에 소개·지원·정책 URL의 로그인 없는 브라우저 요청에서 HTTP 200과 올바른 페이지 제목을 확인했습니다. 지원·정책 페이지의 공개 이메일도 확인했습니다.

로컬에서 확인하려면 프로젝트 루트에서 아래 명령을 실행한 뒤 `http://localhost:8080`을 엽니다.

```sh
python3 -m http.server 8080 --directory web
```

남은 작업:

1. 상품 페이지 기능과 정책의 데이터 처리 설명을 최종 앱과 대조합니다.
2. 실제 URL을 App Store Connect와 앱 내 링크에 연결합니다.
3. 출시 후 소개 페이지에 실제 App Store 다운로드 링크를 추가합니다.

공개 지원·정책 페이지를 준비한 것과 App Store에 바이너리를 업로드하거나 심사를 제출한 것은 별개입니다.
