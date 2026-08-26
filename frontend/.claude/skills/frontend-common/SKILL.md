---
name: frontend-common
description: 프론트엔드 전 레이어 공통 규칙. 도메인 최상위 폴더 구조, 의존 방향(screens→hooks→services→api→lib), 파일 이름·확장자·export, 줄 길이, 람다 관용구, 이름 규칙, 레퍼런스에서 베끼면 안 되는 것, 이관·구축 순서·리뷰 절차를 담는다. frontend/ 아래 파일을 만들거나 고치거나 리뷰할 때 레이어 스킬(frontend-screen·hooks·service·api·lib)과 항상 함께 사용한다.
---

# 프론트엔드 공통 규칙

핵심 사상은 백엔드와 같다: **화면(Controller)과 유스케이스(Service)와 재사용 단위(구현체)를 분리하고, 참조는 한 방향으로만 흐르게 한다.**

이 스킬은 레이어와 무관한 공통 규칙을 담는다. 각 레이어의 상세는 `frontend-screen`·`frontend-hooks`·`frontend-service`·`frontend-api`·`frontend-lib` 가,
TS/RN 문법은 `frontend-style` 이, 서버 계약은 `api-contract` 가 담당한다.

공통 문서(`common/docs/code-review/rules.md`)와 충돌하면 프론트 스킬이 우선한다. 단 CLAUDE.md·README 와 충돌하면 그쪽이 우선한다.

## 정답 코드가 동봉되어 있다

**규칙을 그대로 구현해 `tsc --strict` 와 `expo export` 를 통과한 한 벌이 `frontend/src/` 에 살아 있다.** 글로 된 규칙과 코드가 어긋나면 **코드가 맞다.**

- `src/user/` — 목록·다중선택·삭제·상세 모달이 전부 들어 있는 완결된 수직 슬라이스. 새 화면은 이 파일들을 복사해 이름만 바꾸는 것으로 시작한다.

- `src/splash/` — 파일 8개짜리 작은 도메인. 도메인은 이렇게 작아도 된다.

- `src/common/` — 공통 인프라(apiClient·notify·theme·ServiceError 등). 그대로 둔다.

- `src/map/`·`src/ads/` — 자기완결 선택 모듈 + 제거 절차 README. 플랫폼별 구현이 갈리면 이 둘처럼 **파일 분기**(`.web.tsx`·`admob.web.ts`)로 푼다 — Metro 는 `require` 를 정적으로 해석해 실행 시점 분기로는 웹 번들에서 못 뺀다.

## 도메인이 최상위, 그 아래가 계층

**도메인이 먼저고 계층이 그 아래다.** 한 도메인의 코드는 한 폴더 안에서 끝나야 한다 — 화면 하나를 고치려고 여섯 폴더를 오가면 구조가 틀린 것이다.

**이 지도에 없는 위치의 코드는 리뷰에서 잡는다.**

```
src/
├── app/                    # 라우팅·전역 스토어·부트스트랩. 어떤 도메인도 아니다
├── <도메인>/               # user · share · admin … 도메인 이름이 곧 폴더 이름
│   ├── screens/            # 화면 조립만. 훅 1개 호출 + JSX (상태 0)   웹 프로젝트는 pages/
│   ├── components/         # 이 도메인만 쓰는 표현 컴포넌트
│   ├── hooks/              # 화면 상태 + 유스케이스 오케스트레이션 (useState 는 여기에만)
│   ├── services/           # 업무 규칙 + 상태코드 → 결과/에러 번역 (React 금지)
│   ├── api/                # 엔드포인트 1:1 요청 함수 + 경로 상수
│   ├── lib/                # 이 도메인의 순수 로직·파생 계산
│   ├── types/              # 이 도메인의 서버 DTO·Row 타입
│   └── enums/              # 이 도메인의 메시지·결과·구분 enum
└── common/                 # 여러 도메인이 쓰는 것만. 도메인과 나란히 서는 유일한 비도메인 폴더
    ├── components/<종류>/  # ui · layout · modal · data_table
    └── hooks/ services/ api/ lib/ types/ utils/ enums/
```

**최상위에는 도메인과 `app`·`common` 만 둔다.** 공용 계층을 최상위에 흩어 놓으면 도메인 폴더 옆에 계층 폴더가 서서 한 줄에 두 기준이 섞여 보인다.

이름은 `shared` 가 아니라 **`common`** 이다. `share` 도메인이 있는 앱에서 `shared/` 는 한 글자 차이로 헷갈린다.

**공용 안에도 도메인 폴더를 파지 않는다.** `common/` 에서 하위 폴더로 한 번 더 나누는 것은 `components/<종류>/` 뿐이고 나머지는 평면이다.
`common/hooks/route/` 는 위반이다 — route 만 쓰면 `route/hooks/` 로 가야 하고, 여럿이 쓰면 `common/hooks/` 바로 아래다.

**enum 선언은 `enums/` 에만 둔다.** 한 도메인의 enum 은 `<도메인>/enums/`, 여럿이 쓰는 것과 인프라 enum 은 `src/common/enums/`.
services·hooks·lib 파일 안 인라인 선언은 위반이다.

### 어느 도메인의 것인지 정하는 법

**쓰는 쪽이 정한다.** 화면을 뿌리로 두고 import 를 거꾸로 따라간다 — 한 도메인만 쓰면 그 도메인이 갖고, 둘 이상이 쓰면 공용 평면에 남는다.

손으로 정정하는 예외는 둘뿐이다.

1. **이름이 도메인을 말하는데 다른 도메인도 쓰는 것** — 소유 도메인으로 보낸다. 쓰는 쪽이 그 도메인을 참조한다.

2. **이름에 도메인이 없고 플랫폼 API 만 다루는 것**(`wakeLock`·`geo`·`localCache`) — 한 도메인만 써도 공용에 남는다.
   `lib`·`utils` 는 어떤 도메인 단어도 몰라야 한다는 규칙이 이긴다.

### 의존 방향

한 방향이다. **역방향과 건너뛰기를 둘 다 금지한다.**

```
screens ──▶ hooks ──▶ services ──▶ api ──▶ lib
   └─────▶ components ──▶ hooks
```

- `services` 는 React 를 import 하지 않는다. `useState`·`useCallback` 이 보이면 위치가 틀렸다.

- `api` 는 업무 규칙을 모른다. 상태코드로 분기하거나 사용자 메시지를 만들면 `services` 로 내린다.

- `lib` 은 어떤 도메인 단어도 모른다. 등장하면 그 도메인의 `services`/`lib` 로 옮긴다.

- 화면이 `services`·`api` 를 직접 부르면 건너뛰기 위반이다. 반드시 훅을 통한다. 컴포넌트·훅·화면에서 `fetch`/`axios` 직접 호출 금지.

**도메인끼리는 같은 계층만 가로지른다.** 남의 도메인 훅·서비스 안쪽을 파고들지 않는다 — 필요하면 그 도메인이 밖으로 내주는 것만 쓴다.

서버 상태 라이브러리(React Query 등)는 **미도입**이다. 서버 데이터는 훅 안의 `useState` + 로더 함수로 관리하고, HTTP 는 중앙 클라이언트를 경유한다.

### 옮길 때

1. import 는 손으로 고치지 않는다. **이동표(옛 경로 → 새 경로)를 만들어 상대 경로를 다시 계산**한다.
   `TS2307` 을 이름으로 맞추면 같은 이름이 두 계층에 있을 때 틀린 곳을 가리킨다.

2. **`tsc` 통과가 끝이 아니다.** 부작용 전용 import(`import "./x"`)는 타입 검사를 빠져나간다 — 번들(`npm run build`·`expo export`)까지 돌려야 드러난다.

3. 폴더 이름이 파일명과 겹치면 `user/user/` 같은 중첩이 생긴다. 옮긴 뒤 평탄화한다.

4. 옮긴 뒤 **빈 폴더를 지운다.** 남아 있으면 다음 사람이 그 계층이 아직 산다고 읽는다.

## 파일 이름·확장자·export

같은 구조를 만들어도 이름이 제각각이면 다른 코드베이스가 된다. **레이어는 파일 이름만 보고 판별되어야 한다.**

| 레이어 | 파일 이름 | 확장자 | export |
|---|---|---|---|
| `screens/` | 화면명 PascalCase — `User.tsx` | `.tsx` | **default** (+ 필요 시 named 병행) |
| `components/` | 컴포넌트명 PascalCase — `UserTable.tsx` | `.tsx` | **default** |
| `hooks/` | 훅명 그대로 — `useUserList.ts` | `.ts` | **named** |
| `services/` | 하는 일 camelCase — `userService.ts` | `.ts` | **named** |
| `api/` | 부르는 자원 — `user.ts` | `.ts` | **named** |
| `lib/` | 역할명 camelCase — `apiClient.ts`, `notify.ts` | `.ts` | **named** |
| `types/` | 담는 것 — `user.ts` | `.ts` | **named** |

- **폴더가 이미 도메인을 말하므로 파일 이름에 도메인을 되풀이하지 않는다.**

- **JSX 를 포함하지 않는 파일은 반드시 `.ts`.** 확장자로 레이어를 판별할 수 없게 되기 때문이다.

- **화면(screens·components)만 default export, 나머지 레이어는 전부 named export.** named 로 통일해야 자동완성·일괄 치환이 듣는다.

- 한 파일에 하나의 주역만 둔다. 파일 이름과 주역 이름은 **정확히 같은 철자**여야 한다 — 다르면 검색이 끊긴다.

**스타일은 컴포넌트와 나란한 `이름.styles.ts` 에 둔다(React Native).** `StyleSheet.create` 를 컴포넌트 파일 안에 두지 않고,
색·간격은 `src/common/lib/theme.ts` 토큰만 쓴다(하드코딩 금지).

## 줄 길이 — 100자 자제, import 만 120자 한 줄

**일반 코드는 한 줄 100자를 넘지 않게 자제한다.** 하드 상한은 prettier `printWidth`(120)다.

**import 는 예외다 — 120자까지는 반드시 한 줄로 쓴다.** 120자를 넘으면 딱 3줄로 래핑한다 — 여는 줄, 지정자 전부를 몰아 적은 한 줄(들여쓰기 2), `} from` 줄.
지정자를 한 줄에 하나씩 세로로 펼치지 않는다(포맷터 기본 동작이어도 되돌린다).

```ts
// O — 120자 초과라 3줄 래핑
import {
  createShare, endShare, getShareWatching, isShareApiConfigured, isShareExpired, postShareRoute
} from "../../share/services/shareSession";

// X — 지정자를 한 줄에 하나씩 세로로 펼친 것(포맷터 기본 동작). 화면만 길어진다
import {
  createShare,
  endShare,
  getShareWatching,
} from "../../share/services/shareSession";
```

**여러 줄 객체·return 객체·구조분해도 같은 채워 적기다** — 100자 근처까지 채워 적고 넘치면 다음 줄로 잇는다.
예외: **항목마다 사유 주석이 붙는 블록(DTO 필드 등)은 세로를 유지한다** — 주석이 항목을 따라가야 한다.

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

## 이름 규칙

원칙은 백엔드와 같다: **이름 = 대상 + 행위. 이름만 읽고 한 문장으로 설명되는가?**

| 대상 | 규칙 | 예 |
|---|---|---|
| 화면 | PascalCase, 화면 이름 | `User` |
| 컴포넌트 | PascalCase 명사, 무엇을 그리는지 | `UserTable`, `UserDetailModal` |
| 조립 훅 | `use` + 화면/도메인복수 | `useUsers` |
| 단일책임 훅 | `use` + 대상 + 행위 | `useUserList`, `useUserDelete` |
| 서비스 함수 | 동사 + 대상 | `getUserList`, `deleteUser` |
| api 객체 / 메서드 | 도메인 명사 / 짧은 동사 | `user.list()` |
| 메시지 enum | `<도메인><용도>Messages` | `UserResultMessages` |
| 결과 enum | `<행위>Outcome`, 멤버 UPPER_SNAKE | `DeleteUserOutcome.ALREADY_MISSING` |
| 이벤트 핸들러 / 콜백 prop | `handle`+무엇을 / `on`+행위 | `handleDeleteClick` / `onClose` |
| boolean | `is`/`has`/`can` 긍정형 | `isLoading`, `canSubmit` |

리뷰에서 잡아야 할 이름: `data`·`info`·`temp`(무엇인지 없음), `Comp1`·`Wrapper`, `useData()`·`useStuff()`, 부정형 `notDisabled`.
**반드시 대안 이름을 함께 제시한다.**

## 레퍼런스에서 베끼면 안 되는 것

이 규칙들은 실제 운영 프로젝트에서 도출했지만, 그 프로젝트의 부채까지 규칙이 아니다. 따라 하지 않는다:
테스트 0건 · HTTP 클라이언트 2개 공존 · Error 아닌 객체 throw · api 함수 반환 타입 미선언 · JSX 없는 `.tsx`.
이 저장소에서는 신규 훅·서비스에 테스트를 동반하고(rules.md MUST), 클라이언트는 `apiClient` 하나만 쓴다.

**이미 있는 공용 훅·컴포넌트가 하는 일을 다시 구현하지 않는다.** 쓰기 전에 먼저 찾는다.

## 기존 코드를 이 구조로 옮길 때

한 번에 전면 개편하지 않는다. 손대는 화면 단위로: 화면의 상태를 훅으로 → 단일책임 훅으로 쪼개고 조립 훅으로 묶기 →
HTTP 호출부를 `api/` 로 분리 → 사용자 메시지를 메시지 enum 으로. 기존 테스트가 그대로 통과해야 한다 — 화면 출력·API 계약은 불변이다.

## 새 화면을 만들 때 — 순서

이 순서대로 파일을 만들면 동봉 코드와 같은 모양이 나온다. `src/user/` 가 그대로 따라 쓸 본보기다.

| 순서 | 파일 | 내용 |
|---|---|---|
| 1 | `types/user.ts` | 서버 DTO 를 서버 필드명 그대로. nullable 에 사유 주석 (`frontend-api`) |
| 2 | `api/user.ts` | 경로 상수 + 요청 함수. 반환 타입 명시, 상태코드 분기 없음 (`frontend-api`) |
| 3 | `enums/user.ts` | 메시지·결과 enum 전부 여기 (`frontend-service`) |
| 4 | `services/userService.ts` | 상태코드를 결과/`ServiceError` 로 번역 (`frontend-service`) |
| 5 | `hooks/useUserList.ts` 등 | 단일책임 훅 — `useState` 는 전부 여기 (`frontend-hooks`) |
| 6 | `hooks/useUsers.ts` | 조립 훅 — 소비처별 그룹 반환 + 최초 로드 `useEffect` 하나 (`frontend-hooks`) |
| 7 | `components/*.tsx` + `.styles.ts` | props 로 받은 값만 그린다 (`frontend-screen`) |
| 8 | `screens/User.tsx` + `.styles.ts` | 훅 1개 호출 + JSX. **상태 0** (`frontend-screen`) |
| 9 | `frontend/e2e/<도메인>.spec.ts` | 사용자 흐름 E2E (`frontend-e2e` 스킬) — 유닛 테스트는 두지 않는다 |

마지막으로 **3상태 확인**: 로딩·에러(재시도)·빈 상태가 화면에 다 있는가.

자주 나오는 이탈 두 가지 — 조립 훅 하나에 전부 몰아넣기(5번 생략), `api/` 없이 서비스가 HTTP 직접 호출(2번 생략).

## 코드 리뷰 절차

발견한 것마다 이 형식으로 지적한다: `파일경로:줄 — [위반 규칙] 현재 상태 → 수정 제안`

0. **이해가 먼저.** 변경된 파일 전부와 사용처를 읽는다. 읽지 않고 지적하지 않는다.

1. **페이지 무상태** — 화면에 `useState`/`useEffect`/`useRef` 가 있는가 (`frontend-screen`)

2. **위치·이름·export** — 모든 파일을 위 지도·표와 대조

3. **의존 방향** — 역방향 import, 건너뛰기(화면 → 서비스 직접 호출)

4. **레이어 책임** — api 의 상태코드 분기, 훅의 상태코드, 서비스의 JSX·알림 (`frontend-service`·`frontend-api`)

5. **결과 표현** — 불리언·`null` 반환, 예상된 분기의 예외 던지기 (`frontend-service`)

6. **메시지·알림** — 인라인 한국어 문장, 알림 라이브러리 직접 호출 (`frontend-service`)

7. **타입** — `any`, 사유 없는 nullable, 반환 타입 없는 api 함수, 개명된 DTO 필드 (`frontend-api`)

8. **이름·읽기 난이도** — 이름 표와 대조하고 대안을 제시. 삼항 중첩, index key, 이미 있는 공용 재구현

지적만 하지 않는다. 각 항목에 "왜 문제인지 한 문장 + 고친 모습"까지 제시해야 리뷰가 끝난 것이다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 최상위에 계층 폴더가 도메인과 나란히 | `common/` 으로 모아야 한다 | Critical |
| 공용 아래 도메인 폴더(`common/components/user/`) | 도메인 최상위 위반 — 그 도메인 폴더로 | Critical |
| 컴포넌트·훅·화면에서 `fetch`/`axios`/서비스 직접 호출 | 의존 방향 위반 | Critical |
| 역방향 import (`lib` 가 도메인을, `types` 가 `services` 를) | 계층 붕괴 | Critical |
| JSX 없는 `.tsx`, 훅·서비스의 default export | 파일 규칙 위반 — 레이어 판별 불가 | Important |
| enum 이 `enums/` 밖에 선언됨 | enum 분리 규칙 위반 | Important |
| 판단·누적이 든 람다 체이닝(`reduce`·조건 든 `filter().map()`) | 흐름이 람다 안에 숨는다 — `if`/`for` 로 | Important |
| `data`·`info`·`temp`·`useStuff` 류 이름 | 무엇인지 없는 이름 | Important |
| 이미 있는 공용 훅·컴포넌트의 재구현 | 중복 — 쓰기 전에 먼저 찾는다 | Important |
| 사용처가 하나뿐인데 신설한 추상 계층·설정 옵션 (확장 지점 미리 두기) | 요청받지 않은 추상화 | Critical |

## 체크리스트

- [ ] 최상위가 도메인 + `app`·`common` 뿐이고, 공용 안에 도메인 폴더가 없는가

- [ ] 참조가 `screens → hooks → services → api → lib` 한 방향인가

- [ ] JSX 없는 파일이 `.ts` 이고, default export 는 화면·컴포넌트뿐인가

- [ ] enum 선언이 전부 `enums/` 에 있는가

- [ ] 판단·누적이 람다 체이닝이 아니라 `if`/`for` 로 풀려 있는가 (관용구 제외)

- [ ] 새 화면이 구축 순서(types → api → enums → services → hooks → components → screen)를 따랐는가
