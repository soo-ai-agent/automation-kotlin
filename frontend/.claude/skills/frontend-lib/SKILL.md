---
name: frontend-lib
description: lib 레이어 규칙. 인프라 단일 창구 — HTTP 클라이언트는 앱에 하나(apiClient), 응답 래퍼 벗기기, 이름 있는 객체 인자, 도메인 단어 금지를 다룬다. lib/ 파일을 만들거나 고치거나 리뷰할 때 frontend-common 과 함께 사용한다. "HTTP 클라이언트", "공통 유틸" 요청에도 사용할 것.
---

# lib — 인프라 단일 창구

HTTP 클라이언트는 **앱에 하나**다. 인증 헤더·baseURL·공통 응답 처리를 여기서만 설정한다.

**전문은 동봉 `frontend/src/common/lib/apiClient.ts` 에 있다. 그 파일이 정답이고, 새 클라이언트를 만들지 않는다.** 핵심 둘:

```ts
// 1) 비2xx 도 예외로 던지지 않고 상태코드를 그대로 넘긴다 — 판정은 services 의 몫이다.
const axiosClient: AxiosInstance = axios.create({
    withCredentials: true,
    validateStatus: () => true,
    headers: {Accept: "application/json"},
});

// 2) 공통 응답 래퍼(ApiResponse)를 여기서 한 번 벗겨 낸다. 화면은 래퍼를 모른다.
export type ApiResult<T> =
    | {ok: true; status: number; data: T}
    | {ok: false; status: number};
```

`ApiResult<T>` 는 성공했을 때만 `data` 가 존재한다 — `result.ok` 를 확인하면 `data` 는 `T` 로 확정되므로
호출부에 null 검사가 필요 없다. "성공인데 데이터가 없는" 모순 상태를 타입이 막는다.

- 인자는 **이름 있는 객체**(`{path, body}`)로 받는다. 위치 인자 `get(path, body, config)` 는 호출부에서 안 읽힌다.

- 인증 헤더·공통 처리가 필요하면 `send()` 안에 한 번만 더한다. 호출부는 영향받지 않는다.

- **`lib` 은 어떤 도메인 단어도 모른다.** 등장하면 그 도메인의 `services`/`lib` 로 옮긴다.

- 응답 래퍼 타입(`ApiResponseDTO<T>`)은 lib 에 한 번만 정의한다 — 서버 응답 모양이 바뀌면 고치는 곳은 이 타입 하나다.

그 밖의 공통 창구도 같은 원리다 — 알림은 `notify.ts`(사용 규칙은 `frontend-service`), 주소·키는 `config.ts`,
확인 팝업 브리지는 `confirmDialog.ts`(구조는 `frontend-screen`), 색·간격은 `theme.ts`.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 두 번째 HTTP 클라이언트 신설 | 인증·에러 처리가 두 갈래로 갈라진다 | Critical |
| `lib` 파일 안의 도메인 단어·업무 규칙 | 계층 위반 — 도메인 `services` 로 | Critical |
| `lib` 에서 상태코드 분기·사용자 메시지 | 판정은 services 의 몫 | Critical |
| 위치 인자로 늘어선 클라이언트 시그니처 | 호출부에서 안 읽힌다 — 이름 있는 객체로 | Important |
| Error 가 아닌 평범한 객체 throw | `instanceof` 로 못 걸러지고 스택도 없다 | Important |

## 체크리스트

- [ ] HTTP 클라이언트가 `apiClient` 하나뿐인가

- [ ] `lib` 에 도메인 단어가 없는가

- [ ] 래퍼 벗기기·플랫폼 분기가 lib 안에서 끝나는가
