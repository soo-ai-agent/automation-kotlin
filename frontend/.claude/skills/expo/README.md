# Expo 공식 스킬 (벤더링)

> **이 폴더는 손대지 않습니다.** [expo/skills](https://github.com/expo/skills) 의 사본이고, 원문 그대로 둡니다.

출처: `github.com/expo/skills` · 커밋 `50f59f837ddb7595d8c6683c693207e265d58c43` · 라이선스 MIT([LICENSE](LICENSE))

`plugins/expo/skills/` 의 프레임워크(OSS) 스킬 17종과, 스토어 배포에 필요한 `eas-app-stores` 하나를 그대로 가져왔다.

나머지 EAS(유료 서비스) 스킬은 가져오지 않았다 — 쓰게 되면 그때 같은 방법으로 더한다.

## 왜 저장소 안에 두는가

**프레임워크 규칙의 단일 원본을 하나로 두기 위해서다**(3대 원칙 제3원칙). Expo Router·스타일·데이터 페칭 규칙을
우리 스킬에 베껴 쓰면 상위가 바뀔 때 한쪽만 고쳐져 에이전트마다 다른 규칙을 본다.

플러그인으로 설치하지 않고 커밋한 이유는 `.github/agent/nodes/` 의 CI 에이전트와 Codex 도 읽어야 하기 때문이다.

## 자동으로 읽히지 않는다 — 직접 연다

스킬 탐색은 `skills/<이름>/SKILL.md` 한 단계까지다. 이 폴더는 그보다 한 단계 깊어서 **자동 로딩 대상이 아니다.**

우리 `frontend-*` 스킬이 필요한 자리에서 아래 경로를 가리킨다. 가리켜진 문서는 그때 직접 읽는다.

## 무엇을 언제 여는가

| 스킬 | 언제 |
|---|---|
| [expo-project-structure](expo-project-structure/SKILL.md) | 폴더 구조 — `src/app` 라우트 전용, 화면·서버 코드·플랫폼별 파일의 자리 |
| [expo-router](expo-router/SKILL.md) | 라우팅·네비게이션 — 파일 기반 라우트, `Link`, 스택, 모달·시트, 탭, 헤더 |
| [expo-data-fetching](expo-data-fetching/SKILL.md) | API 호출·캐싱·오프라인·환경변수·토큰 보관 |
| [expo-design-system](expo-design-system/SKILL.md) | 토큰 테마(색·간격·타이포·모서리·그림자·모션), 재사용 컴포넌트 계약, 이탈 감사 |
| [expo-native-ui](expo-native-ui/SKILL.md) | 네이티브다운 화면 스타일 — 시맨틱 색, 컨트롤, 아이콘, 미디어, 시각 효과 |
| [expo-ui](expo-ui/SKILL.md) | `@expo/ui` 네이티브 컴포넌트 — 크로스플랫폼 우선, SwiftUI·Jetpack Compose |
| [expo-animation](expo-animation/SKILL.md) | Reanimated·Gesture Handler·햅틱 애니메이션 |
| [expo-dom](expo-dom/SKILL.md) | 네이티브 앱 안에서 웹 코드를 쓰는 DOM 컴포넌트 |
| [expo-web-to-native](expo-web-to-native/SKILL.md) | 기존 웹/React 앱을 네이티브로 옮길 때 |
| [expo-tailwind-setup](expo-tailwind-setup/SKILL.md) | Tailwind·NativeWind 설정 — **이 저장소는 쓰지 않는다** |
| [expo-module](expo-module/SKILL.md) | Swift·Kotlin 네이티브 모듈과 config plugin |
| [expo-brownfield](expo-brownfield/SKILL.md) | 기존 iOS·Android 앱에 Expo 붙이기 |
| [expo-dev-client](expo-dev-client/SKILL.md) | 개발 클라이언트 빌드 |
| [expo-examples](expo-examples/SKILL.md) | `expo/examples` 저장소의 통합 예제 |
| [expo-app-clip](expo-app-clip/SKILL.md) | iOS App Clip |
| [expo-upgrade](expo-upgrade/SKILL.md) | SDK 업그레이드·의존성 충돌·캐시 정리 |
| [expo-overview](expo-overview/SKILL.md) | 요청이 막연할 때의 출발점 |
| [eas-app-stores](eas-app-stores/SKILL.md) | **스토어 배포** — eas.json 프로필, 빌드·제출, 버전 관리, Play/App Store 절차 (유료 EAS) |

## 이 저장소에서의 예외 둘

1. **각 SKILL.md 끝의 "Submitting Feedback" 절은 실행하지 않는다.** `npx submit-expo-feedback` 은
   작업 내용을 Expo 로 보낸다 — 외부로 나가는 일은 사람이 정한다.

2. **Expo 규칙과 우리 규칙이 부딪히면**, 프레임워크 사용법은 Expo 가, 설계·리뷰 기준은
   `.claude/skills/core-principles`(3대 원칙)와 `common/docs/code-review/rules.md` 가 이긴다.

## 다시 받아올 때

```bash
git clone --depth 1 https://github.com/expo/skills.git /tmp/expo-skills
cp -r /tmp/expo-skills/plugins/expo/skills/<이름> frontend/.claude/skills/expo/
```

받아온 뒤 위 커밋 해시를 새 값으로 고치고, 우리 `frontend-*` 스킬이 가리키는 내용이 아직 맞는지 확인한다.
