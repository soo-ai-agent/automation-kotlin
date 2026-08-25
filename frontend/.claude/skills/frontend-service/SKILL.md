---
name: frontend-service
description: 서비스 레이어와 사용자 메시지 규칙. 상태코드를 결과 enum 또는 ServiceError 로 번역하는 2분법, 메시지 enum(<도메인>/enums/), 알림 단일 창구(notify)와 확인 팝업 호출, 공용 에러 핸들러 두 파일 구조를 다룬다. services/·enums/ 파일을 만들거나 고치거나 리뷰할 때 frontend-common 과 함께 사용한다. "비즈니스 로직", "에러 처리", "알림" 요청에도 사용할 것.
---

# 서비스 (services) — 업무 규칙과 결과 번역

서비스는 **React 를 모르는 순수 TS 모듈**이다. 하는 일은 둘: ① `api/` 호출, ② 그 결과(상태코드·본문)를 **도메인 결과 또는 `ServiceError` 로 번역.**
동봉 정답: `frontend/src/user/services/userService.ts`.

- **상태코드가 등장해도 되는 유일한 레이어**가 서비스다. 훅·컴포넌트에 `status === 404` 가 보이면 위반.

- 분기는 `if` 나열 + early return/throw. `switch` 중첩이나 삼항 사슬로 접지 않는다.

- 서비스 함수는 **최상위 `export function`** 으로 쓴다 (`api`·`lib` 의 객체 네임스페이스와 대비돼 레이어가 눈에 띈다).

- 서버 DTO → 화면 모델 정규화(선택 필드를 빈 문자열·빈 배열로)도 이 레이어에서 **한 번만** 한다.

- **상태코드 번역 같은 짧은 분기 뭉치를 공용 헬퍼로 뽑지 않는다.** 각 서비스 함수가 자기 분기를 가진다 — 함수 하나가 위에서 아래로 완결되게.
  이 정도 중복은 허용하고, 분기가 진짜 커지면(검증 여러 개·부수 로직) 그때 내린다.

## 결과 enum vs ServiceError — 2분법

호출 결과를 **불리언이나 `null` 로 돌려주지 않는다.** 두 갈래 중 하나로 표현한다.

| 상황 | 표현 | 호출부 처리 |
|---|---|---|
| 예상된 비정상 (이미 삭제됨, 대상 없음 …) | **결과 enum 반환** | `if (outcome === X)` 로 분기, 안내 메시지 |
| 진짜 실패 (권한 없음, 서버 오류 …) | **`ServiceError` throw** | `catch` 에서 공용 핸들러 |

```ts
// O — 404 는 "실패"가 아니라 "이미 없음"이라는 결과다
export enum DeleteUserOutcome {
    SUCCESS         = "SUCCESS",
    ALREADY_MISSING = "ALREADY_MISSING",
}

export async function deleteUser(id: number): Promise<DeleteUserOutcome> {
    const result: ApiResult<void> = await user.delete(id);

    if (result.ok) {
        return DeleteUserOutcome.SUCCESS;
    }
    if (result.status === 404) {
        return DeleteUserOutcome.ALREADY_MISSING;
    }
    throw new ServiceError(UserResultMessages.DELETE_ERROR, result.status, ErrorLevel.ERROR);
}
```

`ServiceError` 는 **표시 수준(`ErrorLevel.WARNING/ERROR`)** 을 함께 들고 다닌다. 이것이 알림 종류를 결정한다.
(동봉: `common/services/ServiceError.ts`)

**공용 에러 핸들러는 두 파일로 나눈다.** 한쪽에 몰면 서비스 규칙이 React 에 묶인다.

| 파일 | 역할 | React |
|---|---|---|
| `services/serviceErrorHandler.ts` | 판정 전부 — 401 위임 / `level` 별 알림 / 폴백 로깅. 세션 만료 처리는 **콜백으로 주입** | 금지 |
| `hooks/useServiceErrorHandler.ts` | 얇은 래퍼 — React 의존 동작을 콜백으로 넘기고 `useCallback` 으로 안정화 | 허용 |

**401 은 이 경로 하나로만 처리한다.** 개별 훅이 각자 로그인 화면으로 보내면 안 된다.

## 사용자 메시지는 enum 으로 모은다

문자열 리터럴을 호출부에 흩뿌리지 않는다. **`<도메인>/enums/` 에 메시지 enum 을 선언**하고, 훅·컴포넌트는 그 멤버만 참조한다.

- 이름은 `<도메인><용도>Messages`: `UserResultMessages`, `SessionResultMessages`.

- 멤버는 `UPPER_SNAKE_CASE`, 값은 완성된 한국어 문장(마침표 포함).

- 버튼 문구도 사용자 문장이다 — 화면마다 "확인"·"취소"를 적지 말고 공용 `ConfirmButtonLabel` 을 쓴다.

## 알림은 단일 창구

알림은 `notify.*`(`common/lib/notify.ts`) 하나로만 부른다. 알림 UI 를 아는 유일한 파일이라,
토스트·스낵바로 바꿀 때 고치는 파일이 이 하나뿐이고 호출부는 한 줄도 손대지 않는다 — 그것이 이 창구를 두는 이유다.

- 컴포넌트·훅이 알림 라이브러리(`Alert.alert`·`window.alert` 등)를 직접 부르면 위반. 플랫폼 분기도 notify 안에서 끝난다.

- **확인은 OS 대화상자가 아니라 앱 디자인 팝업으로 묻는다.** 창구는 똑같이 `notify.confirm` 이고 `Promise<boolean>` 을 돌려준다.
  되돌릴 수 없는 동작(삭제·종료)에만 `destructive: true` — 확인 버튼이 위험색으로 바뀐다. (그리는 구조는 `frontend-screen` 의 전역 확인 팝업 절)

- **폴백은 화면을 유지하는 수단이지 실패를 숨기는 수단이 아니다.** 데이터 로드 실패로 폴백을 그릴 때는 반드시 `notify` 로 알린다(세션당 1회로 반복 억제 가능).
  조용한 폴백은 사용자가 빠진 데이터를 정상으로 믿게 만든다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 훅·컴포넌트·화면의 `result.status ===` 분기 | 상태코드 번역은 services 전담 | Critical |
| services 파일에 React import | 계층 붕괴 — services 는 React 를 모른다 | Critical |
| `window.alert`/`confirm`/`Alert.alert` 직접 호출 | 알림 단일 창구(`notify`) 위반 | Critical |
| 결과를 boolean·문자열·`null` 로 반환 | 2분법 위반 | Important |
| 사용자 문장 인라인 문자열 | 메시지 enum 위반 | Important |
| 알림 없는 조용한 폴백 | 고장이 정상으로 보인다 | Critical |
| 개별 훅의 자체 401 처리 | 세션 만료 경로 이원화 | Important |
| 상태코드 번역 분기를 공용 헬퍼로 추출 | 함수 완결성 훼손 — 이 중복은 허용 | Important |

## 체크리스트

- [ ] 상태코드 분기가 services 에만 있는가

- [ ] 예상된 비정상은 결과 enum, 진짜 실패는 `ServiceError` throw 인가

- [ ] 사용자 문장이 전부 메시지 enum 에 있고, 알림이 `notify` 경유인가

- [ ] 401 이 공용 핸들러 한 경로로만 처리되는가
