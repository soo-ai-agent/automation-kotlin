---
name: frontend-route
description: src/app 라우트 폴더의 저장소 고유 규칙. 라우트 파일이 하는 일 셋(파라미터 읽기·화면 렌더·default export), 화면 본체를 라우트에 두지 않기, 이 저장소의 라우트 목록과 루트 레이아웃 구성, 모달을 라우트로 만들지 컴포넌트로 만들지 판정, 라우트를 지울 때 절차를 담는다. Expo Router 사용법 자체는 벤더링된 expo/expo-router 가 정본이다. src/app/ 아래 파일을 만들거나 고치거나, 화면을 새로 연결하거나 네비게이션을 바꿀 때 사용한다. "라우팅", "네비게이션", "화면 이동", "모달 띄우기" 요청에도 사용할 것.
---

# 라우트 (src/app) — URL 과 화면을 잇는 얇은 층

**Expo Router 사용법의 정본은 [expo/expo-router](../expo/expo-router/SKILL.md) 다** — 동적 라우트·그룹 라우트·`Link`·
스택·탭·헤더·시트는 거기를 읽는다. 폴더 규칙은 [expo/expo-project-structure](../expo/expo-project-structure/SKILL.md).

이 문서는 그 위에 얹는 저장소 규칙만 담는다.

## 라우트 파일이 하는 일은 셋뿐이다

1. 라우트 고유 관심사 처리 — URL 파라미터·검색 파라미터 읽기

2. `screens/` 의 화면 하나 렌더

3. `export default`

```tsx
// src/app/map.tsx — 동봉 정답
import {Map} from "@/screens/map";

export default function MapRoute() {
    return <Map />;
}
```

파라미터가 있으면 라우트에서 한 번만 변환해 화면에 넘긴다 — **URL 파라미터는 언제나 문자열이라** 화면이 매번 변환하지 않는다.

```tsx
// src/app/user/[id].tsx
const {id} = useLocalSearchParams<{id: string}>();
return <UserDetail userId={Number(id)} />;
```

**화면 본체를 라우트 파일에 쓰지 않는다.** 라우트가 커지면 그것은 화면이고, `screens/` 로 간다.

라우트 파일에 `useState`·데이터 로딩·컴포넌트 정의가 보이면 위반이다 — 상태는 훅에, 그리는 것은 화면에 있다.

## 지금 있는 라우트

| 파일 | URL | 그리는 화면 |
|---|---|---|
| `src/app/_layout.tsx` | — | 스택 정의 + 스플래시 관문 + 확인 팝업 호스트 |
| `src/app/index.tsx` | `/` | `screens/user` |
| `src/app/map.tsx` | `/map` | `screens/map` — 선택 기능([frontend/docs/map.md](../../../docs/map.md)) |
| `src/app/+not-found.tsx` | 그 밖의 모든 주소 | 안내 + "처음으로". 없으면 Expo Router 개발용 화면이 사용자에게 보인다 |

**`"/"` 에 걸리는 라우트가 반드시 있어야 한다.** 없으면 앱이 빈 화면으로 뜬다.

## 루트 레이아웃이 지는 셋

`src/app/_layout.tsx` 하나가 앱 전체에 하나뿐이어야 하는 것들을 건다. **화면이나 컴포넌트에서 다시 걸지 않는다.**

| 무엇 | 왜 여기인가 |
|---|---|
| `<Stack>` 정의 | 스택·탭 정의는 반드시 `_layout.tsx` (Expo Router 규칙) |
| `<ConfirmDialogHost />` | 확인 팝업을 그리는 자리 — 앱에 하나 (`frontend-screen`) |
| `initializeAds()` | 광고 SDK 초기화는 앱당 한 번 ([frontend/docs/ads.md](../../../docs/ads.md)) |
| `export function ErrorBoundary` | 렌더 중 예외를 받는 자리. Expo Router 가 레이아웃의 이 export 를 찾아 쓴다 |

스플래시 관문(`useSplashGate`)도 여기 있다 — **에셋 준비와 최소 노출 시간을 둘 다 기다리는 동안** 스택 대신 스플래시를 그린다.

네이티브 스플래시는 `expo-splash-screen` 이 잡고 있다가 우리 스플래시가 그려진 뒤 내려간다. 그 순서를 `use-splash-gate.ts` 하나가 쥐고 있으니
`preventAutoHideAsync`·`hideAsync` 를 다른 파일에서 다시 부르지 않는다 — 두 곳에서 부르면 사이에 빈 화면이 스친다.

## 모달을 라우트로 만들지 정하는 기준

**판정은 하나 — 그 모달이 URL 로 열려야 하는가.**

| 그렇다 | 아니다 |
|---|---|
| 공유 링크로 바로 열려야 한다 | 화면 위에 잠깐 겹치는 상세·확인 |
| 뒤로 가기로 닫혀야 한다 | 부모가 ref 로 여는 것으로 충분하다 |
| → 라우트 + `presentation: "modal"` (`expo-router`) | → 컴포넌트 모달 (`frontend-screen` 의 ref 패턴) |

지금 저장소의 사용자 상세 모달과 확인 팝업은 둘 다 후자다.

## 라우트를 지우거나 옮기면 옛 파일을 지운다

**옛 라우트 파일이 남아 있으면 그 URL 이 계속 살아서, 지운 줄 알았던 화면이 열린다.**

선택 기능을 들어낼 때가 특히 그렇다 — `frontend/docs/map.md` 의 절차가 `src/app/map.tsx` 삭제를 첫 항목으로 두는 이유다.

옮긴 뒤 `"/"` 라우트가 여전히 있는지 확인하고 `npm run build` 를 돌린다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| `app/` 안의 컴포넌트·타입·유틸·훅 파일 | 그것도 라우트가 된다 — 형제 폴더로 | Critical |
| 라우트 파일이 화면 본체·`useState`·데이터 로딩을 품고 있다 | 화면은 `screens/`, 상태는 훅 | Critical |
| `"/"` 에 걸리는 라우트가 없다 | 앱이 빈 화면으로 뜬다 | Critical |
| 기능을 들어내고 남겨 둔 옛 라우트 파일 | 지운 줄 알았던 URL 이 산다 | Critical |
| 화면·컴포넌트에서 만든 네비게이터 | 스택·탭은 `_layout.tsx` 의 일 | Important |
| 확인 팝업 호스트·SDK 초기화가 루트 레이아웃 밖에 | 앱에 하나여야 하는 것이 둘이 된다 | Important |
| 라우트가 파라미터를 문자열 그대로 화면에 넘긴다 | 변환은 라우트에서 한 번 | Important |
| 경로 문자열을 여러 파일에 손으로 반복 | `src/constants/` 로 모은다 | Important |

## 체크리스트

- [ ] `app/` 안에 라우트와 `_layout` 말고 아무것도 없는가

- [ ] 라우트 파일이 파라미터 읽기 + 화면 렌더 + default export 뿐인가

- [ ] `"/"` 라우트가 있는가

- [ ] 스택·확인 팝업 호스트·SDK 초기화가 `_layout.tsx` 에만 있는가

- [ ] 라우트를 지웠다면 그 파일까지 지웠는가
