---
name: frontend-common
description: 프론트엔드 전 폴더 공통 규칙. 이 저장소의 src/ 폴더 지도와 의존 방향(app→screens→components·hooks→utils), 무엇이 Expo 공식 스킬 담당이고 무엇이 저장소 고유 규칙인지, 파일 이름·export, 줄 길이, 람다 관용구, 이름 규칙, 새 화면 구축 순서, 리뷰 절차를 담는다. frontend/ 아래 파일을 만들거나 고치거나 리뷰할 때 폴더 스킬(frontend-route·screen·hooks·api)과 항상 함께 사용한다.
---

# 프론트엔드 공통 규칙

폴더 구조는 Expo 공식 스킬 `expo-project-structure` 의 골격 그대로다. **역할이 최상위 폴더이고, `src/app` 은 라우트 전용이다.**

## 프레임워크 규칙은 Expo 공식 스킬이 정본이다

**폴더 구조·라우팅·스타일·데이터 페칭의 규칙 본문을 이 폴더에 베껴 쓰지 않는다.** 저장소 안에 사본이 있으니 그것을 연다.

| 알고 싶은 것 | 여는 문서 |
|---|---|
| 폴더 구조, 라우트 전용 `app/`, 콜로케이션, 플랫폼별 파일, kebab-case | [expo/expo-project-structure](../expo/expo-project-structure/SKILL.md) |
| 라우트·네비게이션·모달 표시 | [expo/expo-router](../expo/expo-router/SKILL.md) |
| 토큰 테마, 재사용 컴포넌트 계약, 승격 조건 | [expo/expo-design-system](../expo/expo-design-system/SKILL.md) |
| HTTP·캐싱·환경변수·토큰 보관 | [expo/expo-data-fetching](../expo/expo-data-fetching/SKILL.md) |
| 네이티브다운 스타일·컨트롤 | [expo/expo-native-ui](../expo/expo-native-ui/SKILL.md) |

색인과 벤더링 규칙은 [expo/README.md](../expo/README.md) 에 있다.

**이 스킬이 담는 것은 Expo 가 말하지 않는 저장소 고유 규칙뿐이다** — 의존 방향, 이름, 줄 길이, 구축 순서, 리뷰 절차.

충돌하면 프레임워크 사용법은 Expo 가, 설계·리뷰 기준은 `core-principles`(3대 원칙)와 `common/docs/code-review/rules.md` 가 이긴다.

## 정답 코드가 동봉되어 있다

**규칙을 그대로 구현해 `tsc --strict` 와 `expo export` 를 통과한 한 벌이 `frontend/src/` 에 살아 있다.** 글로 된 규칙과 코드가 어긋나면 **코드가 맞다.**

- `src/screens/user/` — 목록·다중선택·삭제·상세 모달이 전부 들어 있는 완결된 화면. 새 화면은 이 파일들을 복사해 이름만 바꾸는 것으로 시작한다.

- `src/screens/map/` — 파일 하나짜리 작은 화면. 화면은 이렇게 작아도 된다.

- `src/api/user.ts` — 서버 DTO·요청 함수·상태코드 번역이 한 파일에 완결된 본보기.

- `src/components/kakao-map-view.tsx` + `.web.tsx` — 플랫폼별 파일 분기의 본보기.

## src/ 폴더 지도

**이 지도에 없는 위치의 코드는 리뷰에서 잡는다.** 골격의 근거는 `expo-project-structure` 이고, 여기 적는 것은 이 저장소의 실제 배치다.

```
frontend/
├── assets/                        # 아이콘·스플래시. 스토어 제출물이다 (docs/release.md)
├── docs/                          # 선택 기능 안내(지도·광고)와 배포 절차. src 밖이다
├── e2e/                           # Playwright 사용자 흐름 테스트 (frontend-e2e)
├── src/
│   ├── app/                       # 라우트 전용 — 이 안의 모든 파일이 라우트다
│   │   ├── _layout.tsx            #   스택·스플래시 관문·확인 팝업 호스트
│   │   ├── index.tsx              #   "/" — 사용자 화면
│   │   └── map.tsx                #   "/map" — 지도 화면
│   ├── components/                # 두 화면 이상이 쓰는 UI
│   │   ├── kakao-map-view.tsx
│   │   ├── kakao-map-view.web.tsx #   플랫폼별 변형
│   │   └── kakao-map-view.types.ts#   두 변형이 공유하는 props
│   ├── screens/                   # 라우트가 그리는 화면 본체
│   │   ├── user/
│   │   │   ├── components/        #   이 화면만 쓰는 컴포넌트
│   │   │   ├── hooks/             #   이 화면만 쓰는 훅
│   │   │   └── index.tsx
│   │   └── map/index.tsx
│   ├── hooks/                     # 두 화면 이상이 쓰는 훅
│   ├── api/                       # 서버와 말하는 코드 — 자원마다 한 파일
│   │   ├── client.ts              #   HTTP 창구 하나
│   │   ├── user.ts                #   한 자원의 DTO·요청 함수·결과 번역
│   │   └── app-info.ts
│   ├── utils/                     # 순수 헬퍼 · 플랫폼 래퍼 · 나란한 테스트
│   │   └── format-date.ts
│   ├── constants/                 # 사용자 문장 — 화면·기능마다 한 파일
│   │   ├── user.ts
│   │   ├── map.ts
│   │   └── index.ts               #   재노출. 부르는 쪽은 언제나 `@/constants`
│   └── theme.ts                   # 색 두 벌(밝게·어둡게) + 간격·모서리 토큰
├── app.json                       # 앱 이름·식별자·플러그인·스플래시
├── eas.json                       # 빌드·제출 프로필 (development · preview · production)
└── package.json
```

폴더가 하는 일은 한 줄로 말해진다.

| 폴더 | 담는 것 | 담지 않는 것 |
|---|---|---|
| `app/` | 라우트 파일과 `_layout` 뿐 | 컴포넌트·타입·유틸·훅 — **하나도** |
| `components/` | 두 화면 이상이 쓰는 UI | 서버 통신, 업무 규칙 |
| `screens/` | 라우트가 그리는 화면 본체 | `useState`·`useEffect` |
| `hooks/` | 두 화면 이상이 쓰는 훅 | JSX, HTTP 상태코드 |
| `api/` | 서버 DTO·요청 함수·상태코드 번역 (자원마다 한 파일) | React import, JSX |
| `utils/` | 순수 헬퍼·플랫폼 래퍼 | React import, JSX, 도메인 단어 |
| `constants/` | 사용자 문장 (화면·기능마다 한 파일) | 계산·분기 |
| `theme.ts` | 색 두 벌·간격·모서리 토큰, `useColors`·`useStyles` | 화면별 스타일 |

### `server/` 와 `app/api/` — 이 저장소는 쓰지 않는다

Expo 는 `app/` 안의 파일 이름에 `+api` 를 붙이면 서버에서 도는 API 라우트가 되고, 그 전용 헬퍼를 `src/server/` 에 둔다.

**이 저장소의 서버는 Kotlin 백엔드 하나다.** 프론트에 서버 코드를 두지 않으므로 `app/api/`·`src/server/` 폴더를 만들지 않는다.

만들어야 할 이유가 생기면 폴더를 짓기 전에 사람에게 보고한다 — 서버가 둘이 되는 결정이라 합의가 필요하다.

## 의존 방향

한 방향이다. **역방향과 건너뛰기를 둘 다 금지한다.**

```
app/ ──▶ screens/ ──▶ components/ ──▶ hooks/ ──▶ api/ ──▶ utils/ ──▶ constants/ · theme.ts
             └──────────────────────────▶ hooks/
```

- **아무도 `app/` 을 import 하지 않는다.** 라우트는 최상단이다 — `screens/` 가 `app/` 을 참조하면 방향이 뒤집힌 것이다.

- `utils/` 는 React 를 import 하지 않는다. `useState`·`useCallback` 이 보이면 위치가 틀렸다.

- **`utils/` 에는 두 종류가 산다** — 헷갈리기 쉬우니 나눠 읽는다.

  | 종류 | 예 | 알아도 되는 것 | 몰라야 하는 것 |
  |---|---|---|---|
  | 순수 헬퍼 | `format-date.ts`, `list-state.ts` | 없음 — 다른 프로젝트에 그대로 옮겨도 말이 된다 | 우리 도메인 단어 전부 |
  | 플랫폼·SDK 래퍼 | `admob.ts`, `kakao-map-html.ts`, `notify.ts` | 그 SDK·플랫폼 이름(AdMob·Kakao) | **우리 업무 규칙** |

  판정은 하나 — **"우리 서비스의 업무 규칙을 아는가."** `admob.ts` 가 AdMob 을 아는 것은 정상이고,
  사용자 삭제 규칙을 아는 것은 위반이다. 업무 규칙이 등장하면 그 화면 폴더 안이나 `api/` 의 자원 모듈로 옮긴다.

- 화면이 `api/` 의 요청 함수를 직접 부르면 건너뛰기 위반이다. 반드시 훅을 통한다. 컴포넌트·훅·화면에서 `fetch` 직접 호출 금지.

서버 상태 라이브러리(React Query 등)는 **미도입**이다. 서버 데이터는 훅 안의 `useState` + 로더 함수로 관리하고,
HTTP 는 `api/client.ts` 하나를 경유한다. 도입을 검토한다면 `expo-data-fetching` 을 읽고 사람에게 보고한 뒤 정한다.

## 파일 이름·export

**파일 이름은 전부 kebab-case 다**(`expo-project-structure`·`expo-router` 규칙). 특수문자를 쓰지 않는다.

| 폴더 | 파일 이름 | 확장자 | export |
|---|---|---|---|
| `app/` | URL 조각 — `map.tsx`, `user/[id].tsx` | `.tsx` | **default** (Expo Router 요구) |
| `components/` | 컴포넌트 역할 — `user-table.tsx` | `.tsx` | **named** |
| `screens/` | 화면 이름 — `user/index.tsx` | `.tsx` | **named** |
| `hooks/` | `use-` + 대상 — `use-user-list.ts` | `.ts` | **named** |
| `api/` | 자원 — `user.ts`, `client.ts` | `.ts` | **named** |
| `utils/` | 역할 — `format-date.ts`, `notify.ts` | `.ts` | **named** |
| `constants/` | 화면·기능 — `user.ts`, `map.ts` | `.ts` | **named** |

- **`app/` 안의 파일만 default export 다.** 그 밖에는 전부 named export — 자동완성·일괄 치환이 듣는다.

- **파일 이름은 kebab-case, 그 안의 컴포넌트·훅 이름은 원래 표기다.** `user-table.tsx` 가 `UserTable` 을, `use-user-list.ts` 가 `useUserList` 를 export 한다.
  둘은 같은 낱말이어야 한다 — 다르면 검색이 끊긴다.

- **JSX 를 포함하지 않는 파일은 반드시 `.ts`.**

- import 는 상대 경로가 아니라 별칭 `@/` 로 쓴다(`tsconfig.json` 의 `paths`). 같은 화면 폴더 안에서만 상대 경로를 쓴다.

## 줄 길이 — 100자 자제, import 만 120자 한 줄

**일반 코드는 한 줄 100자를 넘지 않게 자제한다.** 하드 상한은 120자이고 `npm run lint` 의 `@stylistic/max-len` 이 강제한다.

**import 는 예외다 — 120자까지는 반드시 한 줄로 쓴다.** 120자를 넘으면 딱 3줄로 래핑한다 — 여는 줄, 지정자 전부를 몰아 적은 한 줄(들여쓰기 2), `} from` 줄.
지정자를 한 줄에 하나씩 세로로 펼치지 않는다(포맷터 기본 동작이어도 되돌린다).

```ts
// O — 120자 초과라 3줄 래핑
import {
  createShare, endShare, getShareWatching, isShareApiConfigured, isShareExpired, postShareRoute
} from "@/utils/share-api";

// X — 지정자를 한 줄에 하나씩 세로로 펼친 것(포맷터 기본 동작). 화면만 길어진다
import {
  createShare,
  endShare,
  getShareWatching,
} from "@/utils/share-api";
```

**여러 줄 객체·return 객체·구조분해도 같은 채워 적기다** — 100자 근처까지 채워 적고 넘치면 다음 줄로 잇는다.
예외: **항목마다 사유 주석이 붙는 블록(DTO 필드 등)은 세로를 유지한다** — 주석이 항목을 따라가야 한다.

**이 배치만은 도구가 강제하지 않는다.** `eslint.config.js` 에 객체 줄바꿈 규칙을 일부러 넣지 않았다 —
Prettier 를 쓰지 않는 이유도 같다(속성을 강제로 한 줄씩 펼치고 그 동작을 끌 수 없다). 나머지 포맷은 전부 도구가 잡는다.

## 람다는 관용구까지 — 판단은 풀어 쓴다

짧은 코드 ≠ 단순한 코드다. 판단(조건)·누적이 람다 안에 숨으면 흐름을 눈으로 따라갈 수 없다.

```ts
// X — 조건 두 개와 변환이 한 줄 체이닝에 눌려 있다
const overdueIds = orders.filter((o) => o.status !== "DONE" && isPast(o.dueAt)).map((o) => o.id);

// O — 판단이 for 안에 눈으로 보인다
const overdueIds: number[] = [];
for (const order of orders) {
    if (order.status === "DONE") {
        continue;
    }
    if (isPast(order.dueAt)) {
        overdueIds.push(order.id);
    }
}
```

여러 줄 업무 로직이 익명 화살표에 들어가면 이름 있는 함수로 뺀다 — 이름이 의도를 말하게. (백엔드 `kotlin-common` 의 같은 규칙과 짝)

**관용구는 허용한다** — React 가 콜백을 요구하는 자리까지 풀면 오히려 읽기 어려워진다:

- 훅 인자: `useCallback(() => …)`, `useEffect(() => …)`, `useMemo(() => …)`

- JSX 이벤트 핸들러: `onPress={() => openDetail(item.id)}`

- 목록 API: `keyExtractor`, `renderItem`(JSX 반환)

- **한 줄** 변환·비교의 `map`/`filter`: `users.map((u) => u.id)`

판정 기준은 하나 — **람다 본문에 판단이나 누적이 들어 있는가.** 들어 있으면 푼다.

## 포맷은 도구가 잡는다

들여쓰기·따옴표·세미콜론·후행 쉼표·줄 길이는 **`npm run lint` 가 강제한다**(Expo 공식 `eslint-config-expo` + `@stylistic`).
어긋나면 `npm run lint:fix` 가 고친다. PR 에서도 돈다(`.github/workflows/frontend-check.yml`).

리뷰에서 포맷을 지적하지 않는다(rules.md "리뷰 범위 밖"). 도구가 통과시킨 것은 통과된 것이다.

린트는 포맷만 보는 게 아니다 — React 훅·ref 규칙도 함께 잡는다. 실제로 이 저장소에서
훅이 ref 를 담은 객체를 통째로 반환하던 자리 6곳을 린트가 찾아냈고, 호출부에서 구조분해하는 것으로 고쳤다.

## 이름 규칙

원칙은 백엔드와 같다: **이름 = 대상 + 행위. 이름만 읽고 한 문장으로 설명되는가?**

| 대상 | 규칙 | 파일 | 안의 이름 |
|---|---|---|---|
| 라우트 | URL 조각 그대로 | `app/map.tsx` | `MapRoute` |
| 화면 | 화면 이름 | `screens/user/index.tsx` | `User` |
| 컴포넌트 | 무엇을 그리는지 | `components/user-table.tsx` | `UserTable` |
| 조립 훅 | `use` + 화면/복수형 | `screens/user/hooks/use-users.ts` | `useUsers` |
| 단일책임 훅 | `use` + 대상 + 행위 | `use-user-list.ts` | `useUserList` |
| 요청 모듈 | 자원 이름 | `api/user.ts` | `getUserList`, `deleteUser` |
| 메시지 enum | `<화면><용도>Messages` | `constants/user.ts` | `UserResultMessages` |
| 결과 enum | `<행위>Outcome`, 멤버 UPPER_SNAKE | 요청 모듈 안 | `DeleteUserOutcome.ALREADY_MISSING` |
| 이벤트 핸들러 / 콜백 prop | `handle`+무엇을 / `on`+행위 | — | `handleDeleteClick` / `onClose` |
| boolean | `is`/`has`/`can` 긍정형 | — | `isLoading`, `canSubmit` |

리뷰에서 잡아야 할 이름: `data`·`info`·`temp`(무엇인지 없음), `Comp1`·`Wrapper`, `useData()`·`useStuff()`, 부정형 `notDisabled`.
**반드시 대안 이름을 함께 제시한다.**

## 새 화면을 만들 때 — 순서

아래에서 위로 만든다. `src/screens/user/` 가 그대로 따라 쓸 본보기다.

| 순서 | 파일 | 내용 |
|---|---|---|
| 1 | `src/api/<자원>.ts` | 서버 DTO 를 서버 필드명 그대로 + 요청 함수 + 상태코드 → 결과/`ServiceError` 번역 (`frontend-api`) |
| 2 | `src/constants/<화면>.ts` + `index.ts` 재노출 | 그 화면의 사용자 문장 (`frontend-api`) |
| 3 | `src/screens/<화면>/hooks/use-*.ts` | 단일책임 훅 — `useState` 는 전부 여기 (`frontend-hooks`) |
| 4 | `src/screens/<화면>/hooks/use-<화면>s.ts` | 조립 훅 — 소비처별 그룹 반환 + 최초 로드 `useEffect` 하나 (`frontend-hooks`) |
| 5 | `src/screens/<화면>/components/*.tsx` | props 로 받은 값만 그린다. 스타일은 파일 맨 아래, **색이 들어가면 `useStyles(createStyles)`** (`frontend-screen`) |
| 6 | `src/screens/<화면>/index.tsx` | 상태 훅 1개 + `useStyles` + JSX. **화면 자체의 상태 0** (`frontend-screen`) |
| 7 | `src/app/<라우트>.tsx` | 화면 하나 렌더 + `export default` (`frontend-route`) |
| 8 | `frontend/e2e/<화면>.spec.ts` | 사용자 흐름 E2E (`frontend-e2e`) — 화면에 유닛 테스트는 두지 않는다 |

두 화면 이상이 쓰게 된 컴포넌트·훅만 `src/components/`·`src/hooks/` 로 올린다(승격 조건 셋은 `expo-design-system`).

마지막으로 **3상태 확인**: 로딩·에러(재시도)·빈 상태가 화면에 다 있는가.

### 끝났는지 확인하는 법

셋이 다 통과해야 끝난 것이다. 순서가 있다 — E2E 가 개발 서버를 띄우면서 라우트 타입을 만들고, 그래야 `tsc` 가 `<Link href>` 오타까지 잡는다.

```bash
npm run lint     # Expo 공식 규칙 + 포맷. 훅·ref 규칙도 함께 본다
npm run e2e      # 사용자 흐름. .expo/types 라우트 타입이 여기서 생성된다
npm run build    # tsc --noEmit + 웹 번들
```

PR 에서도 이 순서 그대로 돈다(`.github/workflows/frontend-check.yml`).

자주 나오는 이탈 셋 — 조립 훅 하나에 전부 몰아넣기(3번 생략), `api/` 없이 훅이 HTTP 직접 호출(1번 생략),
라우트 파일 안에 화면 본체를 그대로 쓰기(6번 생략).

## 코드 리뷰 절차

발견한 것마다 이 형식으로 지적한다: `파일경로:줄 — [위반 규칙] 현재 상태 → 수정 제안`

0. **이해가 먼저.** 변경된 파일 전부와 사용처를 읽는다. 읽지 않고 지적하지 않는다.

1. **`app/` 오염** — 라우트 아닌 파일이 `app/` 안에 있는가, 라우트가 화면 본체를 품고 있는가 (`frontend-route`)

2. **화면 무상태** — 화면에 `useState`/`useEffect`/`useRef` 가 있는가 (`frontend-screen`)

3. **위치·이름·export** — 모든 파일을 위 지도·표와 대조. kebab-case 인가, default export 가 `app/` 뿐인가

4. **의존 방향** — 역방향 import(`screens` 가 `app` 을), 건너뛰기(화면 → 요청 함수 직접 호출)

5. **콜로케이션** — 한 화면만 쓰는 것이 공용 폴더에 올라가 있는가 (`expo-design-system` 의 승격 조건 셋)

6. **책임** — `utils/` 의 React import, 훅의 상태코드, 화면의 `try/catch` (`frontend-api`·`frontend-hooks`)

7. **결과 표현** — 불리언·`null` 반환, 예상된 분기의 예외 던지기 (`frontend-api`)

8. **메시지·알림** — 인라인 한국어 문장, 알림 라이브러리 직접 호출 (`frontend-api`)

9. **타입** — `any`, 사유 없는 nullable, 반환 타입 없는 요청 함수, 개명된 DTO 필드 (`frontend-api`)

10. **이름·읽기 난이도** — 이름 표와 대조하고 대안을 제시. 삼항 중첩, index key, 이미 있는 공용 재구현

지적만 하지 않는다. 각 항목에 "왜 문제인지 한 문장 + 고친 모습"까지 제시해야 리뷰가 끝난 것이다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| `app/` 안의 컴포넌트·타입·유틸·훅 파일 | 라우트 전용 위반 — 그것도 라우트가 된다 | Critical |
| 라우트 파일이 화면 본체를 직접 품고 있다 | `screens/` 로 빼고 라우트는 렌더만 | Critical |
| `screens/`·`components/` 가 `app/` 을 import | 역방향 — 라우트는 최상단이다 | Critical |
| 컴포넌트·훅·화면에서 `fetch`·요청 함수 직접 호출 | 의존 방향 위반 | Critical |
| `api/`·`utils/` 파일의 React import·JSX | 밑바닥 계층 붕괴 | Critical |
| 사용자 문장을 `constants/` 한 파일에 몰아 담음 | 화면마다 같은 파일을 건드려 머지 충돌 — 화면·기능당 한 파일 | Important |
| 옮긴 뒤 남아 있는 옛 라우트 파일 | 그 URL 이 계속 산다 | Critical |
| 사용처가 하나뿐인데 신설한 추상 계층·설정 옵션 | 요청받지 않은 추상화 | Critical |
| Expo 공식 스킬의 규칙 본문을 이 폴더에 베껴 옴 | 단일 원본 위반 — 가리키기만 한다 | Critical |
| 한 화면만 쓰는 컴포넌트·훅이 `components/`·`hooks/` 에 | 승격 조건 미달 — 화면 폴더로 | Important |
| PascalCase·snake_case 파일 이름 | kebab-case 위반 | Important |
| JSX 없는 `.tsx`, `app/` 밖의 default export | 파일 규칙 위반 | Important |
| 별도 `.styles.ts` 파일, `__tests__/` 폴더 | 콜로케이션 위반 — 파일 아래·파일 옆 | Important |
| 플랫폼 차이를 실행 시점 `if` 로 분기 | 웹 번들에서 네이티브 모듈이 안 빠진다 — 파일 분기로 | Important |
| 판단·누적이 든 람다 체이닝 | 흐름이 람다 안에 숨는다 — `if`/`for` 로 | Important |
| `data`·`info`·`temp`·`useStuff` 류 이름 | 무엇인지 없는 이름 | Important |
| 이미 있는 공용 훅·컴포넌트의 재구현 | 중복 — 쓰기 전에 먼저 찾는다 | Important |

## 체크리스트

- [ ] `src/app` 안에 라우트와 `_layout` 말고 아무것도 없는가

- [ ] 참조가 `app → screens → components·hooks → api → utils` 한 방향인가

- [ ] 파일 이름이 전부 kebab-case 이고, default export 가 `app/` 안에만 있는가

- [ ] 한 화면만 쓰는 컴포넌트·훅이 그 화면 폴더 안에 있는가

- [ ] 프레임워크 규칙을 베끼지 않고 `expo/` 문서를 가리켰는가

- [ ] 새 화면이 구축 순서(api → constants → hooks → components → screen → route)를 따랐는가
