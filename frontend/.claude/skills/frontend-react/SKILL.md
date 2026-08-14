---
name: frontend-react
description: >
  React + TypeScript 프론트엔드 코드 작성·수정·리팩터링·리뷰 기준. '프론트',
  'React', '컴포넌트', '훅', '화면', 'UI 코드', '프론트 리뷰' 요청 시 반드시
  사용할 것. 자기완결적 — 규칙을 그대로 구현해 tsc strict 를 통과한
  frontend/src/ 가 곧 정답 코드다(인프라 7개 + 사용자 목록 화면 13개). 핵심: 6단 레이어 고정, 페이지 무상태(useState/useEffect
  금지), 결과 enum vs ServiceError 2분법, 메시지 enum, notify 단일 창구, 모달
  forwardRef. 요약은 Quick Rules, 각 장 전문은 chapters.md. 공통 문서
  (common/docs/code-review/rules.md) 위에 적용하며 충돌 시 이 문서가 우선. 백엔드는
  backend/.claude/skills/kotlin-* 이 담당.
---

# 프론트엔드 코딩 스킬 (React + TypeScript)

> 범용 규칙("얼마나 적게 만들 것인가")은 **ponytail** 이, 언어 무관 공통 규칙은

> **common/docs/code-review/rules.md** 가 담당한다. 이 문서는 React + TS 프론트엔드 고유 규칙만 다루며,

> 공통 문서와 충돌하면 이 문서가 우선한다 (단 CLAUDE.md·README 와 충돌하면 그쪽이 우선).

## 책임

공통 문서가 "좋은 코드란 무엇인가"를 말한다면, 이 문서는 "React에서는 그 코드를 **어느 폴더에, 어떤 이름으로, 어떤 모양으로** 쓰는가"를 말한다.

공통 규칙(타입 명시, guard clause, 과한 설계 금지, 주석, 에러 처리 원칙)은 반복하지 않는다. 두 문서가 충돌하면 이 문서가 우선한다. 단 CLAUDE.md·README 와 충돌하면 그쪽이 우선한다.

핵심 사상은 백엔드와 같다: **화면(Controller)과 유스케이스(Service)와 재사용 단위(구현체)를 분리하고, 참조는 한 방향으로만 흐르게 한다.**

이 스킬의 임무는 두 가지다: ① 규칙에 맞게 작성한다. ② 기존 코드가 규칙을 지키는지, 알아보기 힘든 이름·구조 이탈이 없는지 확인하고 지적한다. (마지막 장 "코드 리뷰 절차")

## 어디부터 읽나

| 지금 하려는 일 | 읽을 곳 |
|---|---|
| 새 화면을 만든다 | **동봉 코드**(바로 아래) → chapters.md 15장 파일 표 → 필요할 때 해당 장 |
| 규칙만 빠르게 확인한다 | Quick Rules |
| 어디에 파일을 둘지 모르겠다 | chapters.md 0장(폴더) · 0-2장(이름·확장자·export) |
| 남의 코드를 리뷰한다 | chapters.md 16장 리뷰 절차 8단계 |
| 부엉이 기존 코드를 옮긴다 | chapters.md 14장 이관 지도 |

**장 구성:** 0 폴더·이름 · 1 페이지 무상태 · 2 훅 · 3 services · 4 api · 5 lib · 6 메시지 enum · 7 결과/에러 · 8 알림 · 9 모달 · 10 상태·useEffect · 11 타입 · 12 이름 · 13 따라 하면 안 되는 것 · 14 부엉이 이관 · 15 구축 순서 · 16 리뷰

## 코드 스타일

- MUST: **페이지·컴포넌트에 `useState`/`useEffect`를 두지 않는다.** 화면 상태는 전부 훅에 있다. (1·2장)

- MUST: 페이지는 **훅 1개를 호출하고 JSX만 반환**한다. 페이지가 50줄을 크게 넘으면 훅 분해가 덜 된 것이다.

- MUST: 서버 통신은 `api/` 의 요청 함수로만 한다. 컴포넌트·훅·페이지에서 `fetch`/`axios` 직접 호출 금지.

- MUST: HTTP 상태코드 분기와 업무 규칙은 `services/` 에 둔다. 훅은 상태코드를 모른다. (3장)

- MUST: 사용자에게 보이는 문장은 전부 `export enum XxxResultMessages` 에 모은다. 호출부 인라인 문자열 금지. (6장)

- MUST: **enum 선언은 `src/enums/` 에만 둔다.** 도메인 enum 은 도메인당 파일 하나(`enums/user.ts`), 인프라 enum 은 각자 파일. services·hooks·lib 파일 안 인라인 선언 금지.

- MUST: 예상된 비정상 분기는 **결과 enum 반환**, 진짜 실패는 **`ServiceError` throw**. 불리언 반환 금지. (7장)

- MUST: 상태코드 번역 같은 짧은 분기 뭉치를 공용 헬퍼로 뽑지 않는다. 각 서비스 함수가 자기 분기를 가진다 — 함수 하나가 위에서 아래로 완결되게. 이 정도 중복은 허용하고, 분기가 진짜 커지면(검증 여러 개·부수 로직) 그때 헬퍼로 내린다.

- MUST: 알림은 `notify.*` 한 창구로만. 컴포넌트에서 `alert`/`Swal`/토스트 직접 호출 금지. (8장)

- MUST: 참조는 `pages → hooks → services → api → lib` 한 방향. 역방향·건너뛰기 금지. (0장)

- MUST: 파일 이름·확장자·export 는 0-2장 표를 따른다. **화면만 default export**, hooks·services·api·lib·types 는 named. JSX 없으면 `.ts`.

- MUST: `any` 금지. API 요청/응답에는 명시적 타입을 붙이고, 지역 변수에도 타입을 적는다. (11장)

- MUST: `unknown` 도 최소화한다. 쓰게 되면 "왜 모양을 보장할 수 없는지" 주석을 반드시 달고(catch 예외, 직렬화 경계 등), 받은 즉시 판정 함수에서 좁힌다. 사유를 못 쓰겠으면 명시적 타입이 있어야 한다는 뜻이다.

- MUST: `nullable`(`?`, `| null`)을 선언하면 "왜 없음이 가능한지"를 주석으로 남긴다. 못 적으면 기본값·빈 컬렉션·전용 타입으로 바꾼다.

- MUST: 스타일 정의(StyleSheet.create·큰 인라인 style·CSS-in-JS)는 컴포넌트에 두지 않고 별도 스타일 파일로 뺀다(RN: `Foo.tsx` → `Foo.styles.ts`).

  (`common/docs/code-review/rules.md` SHOULD "UI·스타일·서비스 분리")

- MUST: React 를 모르는 사람이 읽어도 화면 구조가 보이도록 기초 문법에 충실하게 쓴다.

- SHOULD: 상태·종류·구분 코드처럼 닫힌 값 집합은 문자열 리터럴 union 대신 `enum` 으로 선언하고 멤버는 `UPPER_SNAKE_CASE`.

- SHOULD: 파생값은 상태로 만들지 않고 렌더 중에 계산한다.

- MUST NOT: `useEffect` 를 첫 수단으로 쓰지 않는다. 파생값·이벤트 응답·데이터 로드는 각각 다른 자리가 있다. (10장)

- MUST NOT: 이미 있는 공용 훅/컴포넌트가 하는 일을 다시 구현하지 않는다. 쓰기 전에 먼저 찾는다.

- MUST NOT: 레퍼런스의 "테스트 0건"·"HTTP 클라이언트 2개 공존"을 따라 하지 않는다. (13장)

- **DTO 필드에 습관적 `?` 금지.** 서버가 항상 보내는 필드는 non-optional. 값이 빌 수 있으면 `| null` + 사유 주석. `any`·`object`·`Record<string, unknown>` 으로 데이터를 뭉개지 않는다 (11장).

## 표준 패턴 — 동봉된 정답 코드

**이 스킬은 자기완결적이다.** 참고할 외부 프로젝트가 없어도 된다. 규칙을 그대로 구현한 **동작하는 코드 한 벌**이 프로젝트 초기 코드로 살아 있다:

```
frontend/src/
```

`tsc --strict --noUnusedLocals --noUnusedParameters` 를 통과한 20파일 744줄이다. 글로 된 규칙과 코드가 어긋나면 **코드가 맞다.**

### 이미 제자리에 있는 인프라 7개 (그대로 둔다)

| 파일 | 역할 |
|---|---|
| `lib/apiClient.ts` | 단일 HTTP 클라이언트. 공통 응답 래퍼를 벗겨 `ApiResult<T>` 로 돌려준다 |
| `lib/notify.ts` | 알림 단일 창구. 알림 UI 교체 시 **이 파일만** 고친다 |
| `lib/listState.ts` | 3상태(`ListStatus.OK`/`EMPTY`/`ERROR`) 표현형 |
| `services/ServiceError.ts` | 도메인 실패 + 표시 수준(`ErrorLevel`) |
| `services/serviceErrorHandler.ts` | 에러 판정 전부(React 없음). 세션 만료는 콜백 주입 |
| `hooks/useServiceErrorHandler.ts` | 위 함수의 얇은 React 래퍼 |
| `utils/formatDate.ts` | 날짜 포맷 |

### 이름만 바꿔 따라 쓰는 초기 화면 13개 (사용자 목록 전체)

`types/user.ts` → `api/user.ts` → `services/userService.ts` → `hooks/useUser*.ts` 5개 + `hooks/useUsers.ts`(조립) → `components/data_table/UserTable.tsx`·`UserToolbar.tsx` → `components/modal/UserDetailModal.tsx` → `pages/user/User.tsx`

목록·다중선택·단건/일괄 삭제·상세 모달이 전부 들어 있는 **완결된 수직 슬라이스**다. 새 화면은 이 13개를 열어 `User` 를 자기 도메인 이름으로 바꾸는 것으로 시작한다.

예제 컴포넌트에는 `className` 이 없다. 구조만 보여 주려는 것이고, 실제 화면은 프로젝트의 기존 공용 컴포넌트·토큰으로 입힌다(CLAUDE.md 6절 "틀 준수").

> 참고: 이 규칙들은 실제 운영 프로젝트 `member-info-collect-frontend-main` 에서 도출했다.

> 그 프로젝트가 곁에 있으면 참고해도 좋지만 **없어도 무방하다.** 오히려 그 프로젝트에는

> 따라 하면 안 되는 부채도 있다(13장).

## 사례

각 장(0~16)의 전문과 ❌/✅ 사례는 같은 폴더 `chapters.md` 에 있다. 코드 스타일 목록으로 판단이 안 설 때만 해당 장을 연다.

특히: 1장(페이지 무상태) · 7장(2분법) · 10장(useEffect) · 12장(이름) · 13장(따라 하면 안 되는 것).

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 페이지·컴포넌트에 `useState`/`useEffect` | 페이지 무상태 위반 — 상태는 훅으로 (1·2장) | Critical |
| 훅·컴포넌트·페이지의 `result.status ===` 분기 | 상태코드 번역은 services 전담 (3·7장) | Critical |
| 컴포넌트에서 `fetch`/`axios`/서비스 직접 호출 | 참조 방향 위반 — 컴포넌트는 props 만 그린다 (0장) | Critical |
| `window.alert`/`confirm`/토스트 직접 호출 | 알림 단일 창구(`notify`) 위반 (8장) | Critical |
| `any`, 습관적 `?`, `Record<string, unknown>`, 사유 주석 없는 `unknown` | 자료형 뭉개기 — 데이터 계약 붕괴 (11장) | Critical |
| DTO 필드를 서버 응답과 다른 이름으로 개명 | 서버 계약서(CONTRACT.md)와 눈으로 대조 불가 (11장) | Critical |
| services 파일에 React import | 계층 붕괴 — services 는 React 를 모른다 (3장) | Critical |
| 결과를 boolean/문자열로 반환 | 결과 enum vs `ServiceError` 2분법 위반 (7장) | Important |
| 데이터 로딩 `useEffect` 가 조립 훅 밖에 존재 | effect 자리 규칙 위반 (10장) | Important |
| 단일책임 훅이 다른 단일책임 훅을 import | 조합은 조립 훅의 일 (2장) | Important |
| `key={index}` | 재정렬·삭제 시 상태 꼬임 | Important |
| hooks·services·api·lib 의 default export | export 규칙 위반 — 화면만 default (0-2장) | Important |
| `data`·`info`·`temp`·`useStuff` 류 이름 | 무엇인지 없는 이름 (12장) | Important |
| 사용자 문장 인라인 문자열 | 메시지 enum 위반 (6장) | Important |
| enum 이 `src/enums/` 밖에 선언됨 | enum 분리 규칙 위반 | Important |

## 체크리스트

구조

- [ ] 페이지가 훅 1개 호출 + JSX 뿐인가 (`useState` 0개)

- [ ] 참조가 `pages → hooks → services → api → lib` 한 방향인가

- [ ] JSX 없는 파일이 `.ts` 이고, default export 는 화면뿐인가

- [ ] 새 화면이 15장 구축 순서(types → api → services → hooks → components → page)를 따랐는가

데이터

- [ ] DTO 필드가 서버 이름(Kotlin/Jackson 기본 camelCase) 그대로인가

- [ ] 습관적 `?` 없이, nullable 마다 사유 주석이 있는가

- [ ] `any`·`object`·`Record<string, unknown>` 이 없는가

- [ ] `unknown` 마다 사유 주석이 있고 즉시 좁혀지는가

- [ ] enum 선언이 전부 `src/enums/` 에 있는가

흐름

- [ ] 상태코드 분기가 services 에만 있는가

- [ ] 예상된 비정상은 결과 enum, 진짜 실패는 `ServiceError` throw 인가

- [ ] 사용자 문장이 전부 메시지 enum 에 있고, 알림이 `notify` 경유인가

리뷰

- [ ] chapters.md 16장 리뷰 절차 8단계를 수행했는가
