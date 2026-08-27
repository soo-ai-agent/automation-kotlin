# 스토어 배포 준비

> **이 문서는 사람이 읽습니다.** 앱을 App Store·Play Store 에 올리기 전에 사람이 해야 할 일을 담습니다.

저장소에는 **설정과 자리 표시 에셋까지** 들어 있습니다. 계정·자격증명·심사 서류는 사람만 만들 수 있어 아래 절차가 필요합니다.

## 먼저 — 지금 상태로는 올릴 수 없습니다

아래 넷은 **자리 표시 값**이라 그대로 제출하면 거절되거나 등록 자체가 막힙니다.

| 무엇 | 지금 값 | 왜 막히나 |
|---|---|---|
| 앱 식별자 | `com.example.frontend` (`app.json` 의 `ios.bundleIdentifier`·`android.package`) | Play Console 이 `com.example.*` 등록을 거부한다 |
| 아이콘·스플래시 | `assets/*.png` — 자동 생성한 도형 | Apple 심사 "Placeholder content" 사유 |
| AdMob 앱 ID | 구글 공개 **테스트** 값 | 실제 수익이 안 나고 정책 위반이다 ([ads.md](ads.md)) |
| 앱 이름·slug | `frontend` | 스토어에 그대로 노출된다 |

`extra.eas.projectId` 도 아직 없습니다 — `eas init` 이 계정에 프로젝트를 만들면서 넣어 줍니다.

## 1. 계정 (사람만 가능, 유료)

| 필요한 것 | 어디서 | 비용 |
|---|---|---|
| Apple Developer Program | [developer.apple.com](https://developer.apple.com) | 연 $99 |
| Google Play Console | [play.google.com/console](https://play.google.com/console) | 최초 1회 $25 |
| Expo 계정(EAS) | [expo.dev](https://expo.dev) | 무료 한도 있음, 초과 시 유료 |

**EAS 빌드는 유료 서비스입니다.** 요금은 [expo.dev/pricing](https://expo.dev/pricing) 을 먼저 확인하세요.

## 2. 자리 표시 값 바꾸기

```jsonc
// app.json
"name": "우리 앱 이름",
"slug": "our-app",
"ios":     {"bundleIdentifier": "com.ourcompany.ourapp"},
"android": {"package":          "com.ourcompany.ourapp"}
```

- **식별자는 한 번 정하면 못 바꿉니다.** 스토어에 올린 뒤 바꾸면 다른 앱이 됩니다.

- 아이콘은 `assets/icon.png`(1024×1024, **알파 채널 없이**)와 `assets/adaptive-icon.png`(안드로이드 전경, 투명 유지)을 교체합니다.

- 스플래시는 `assets/splash-icon.png` 와 어두운 모드용 `assets/splash-icon-dark.png` 두 장입니다.

- AdMob 을 쓴다면 `app.json` 플러그인의 `androidAppId`·`iosAppId` 와 `extra.admob*` 를 실제 값으로 바꿉니다. **안 쓴다면 [ads.md](ads.md) 의 절차로 통째로 들어내는 편이 낫습니다** — 광고 SDK 가 있으면 개인정보·추적 고지가 따라옵니다.

## 3. EAS 초기화와 빌드

```bash
npm install -g eas-cli
eas login
cd frontend && eas init          # extra.eas.projectId 를 app.json 에 써 준다

eas build --profile preview      # 내부 배포용 — 실기기에서 먼저 확인한다
eas build --profile production   # 스토어 제출용
```

`eas.json` 에 프로필 셋이 있습니다.

| 프로필 | 쓰임 |
|---|---|
| `development` | dev client — 광고·지도 같은 네이티브 모듈을 개발 중에 확인할 때 |
| `preview` | 내부 배포(APK). 스토어에 올리기 전 실기기 검증 |
| `production` | 스토어 제출. `autoIncrement` 로 빌드 번호가 자동으로 오른다 |

버전은 `appVersionSource: "remote"` 라 EAS 가 관리합니다 — `app.json` 의 `version` 은 사용자에게 보이는 값(1.0.0)만 올리면 됩니다.

## 4. 제출

```bash
eas build -p ios --profile production --submit
eas build -p android --profile production --submit
```

먼저 `eas.json` 의 `submit.production` 을 채웁니다.

- **iOS** — `appleId`(Apple 계정 이메일)와 `ascAppId`(App Store Connect 에서 앱을 만들면 나오는 숫자 ID).

- **Android** — Play Console 에서 만든 서비스 계정 키를 `frontend/google-service-account.json` 으로 두면 됩니다.
  **이 파일은 `.gitignore` 에 들어 있습니다. 절대 커밋하지 마세요.**

## 5. 첫 제출 전 체크리스트

**Play Store**

- [ ] Play Console 에서 앱 만들기
- [ ] 앱 콘텐츠 신고 — 개인정보처리방침 URL, 광고 포함 여부, 데이터 안전 양식
- [ ] 스토어 등록정보 — 제목·설명·스크린샷
- [ ] 콘텐츠 등급 설문
- [ ] 가격·배포 국가
- [ ] 서비스 계정 권한 설정

**App Store**

- [ ] App Store Connect 에서 앱 레코드 만들기
- [ ] 개인정보처리방침 URL (**필수** — 없으면 거절)
- [ ] 스크린샷(기기 크기별), 설명, 키워드
- [ ] 로그인이 필요한 앱이면 **심사용 데모 계정** 제공
- [ ] 자리 표시 콘텐츠(lorem ipsum·테스트 데이터) 제거

**이 템플릿 특유의 것**

- [ ] `src/screens/user/` 예시 화면을 실제 화면으로 바꿨는가 (심사 "최소 기능" 사유)
- [ ] `extra.apiBaseUrl` 이 `localhost` 가 아닌 실제 운영 주소인가
- [ ] 광고를 쓴다면 개인정보처리방침에 광고·추적 고지가 들어갔는가

## 6. 웹 배포는 별개입니다

`frontend/Dockerfile` + `nginx.conf` 로 웹을 따로 배포합니다(`.github/workflows/deploy.yml`). 스토어 배포와 무관하게 돌아갑니다.

## 자세한 절차

벤더링된 Expo 공식 스킬에 단계별 안내가 있습니다 — [`.claude/skills/expo/eas-app-stores/`](../.claude/skills/expo/eas-app-stores/SKILL.md).
`references/` 에 Play Store·App Store·TestFlight·스토어 메타데이터·CI 워크플로가 각각 들어 있습니다.
