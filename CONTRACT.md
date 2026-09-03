# API 계약

> **이 문서는 에이전트가 씁니다.** `api` 노드가 여기에 적고, `web` 노드가 읽어 화면을 만듭니다. 사람이 직접 고칠 일은 없습니다 — 계약이 잘못됐으면 `web` 노드가 아래에 문제를 적어 둡니다.

첫 도메인은 `todo` 다 (`core/core-todo`). 아래 엔드포인트 표가 그 계약이다.

## 응답 래퍼

모든 응답은 `ApiResponse<T>` 로 감싸진다 (`core:core-common` 의 `response/ApiResponse.kt`). 아래 엔드포인트 표에는 **`data` 안쪽의 모양**만 적는다.

```json
{ "result": "SUCCESS", "data": { }, "error": null }
{ "result": "ERROR",   "data": null, "error": { "code": "...", "message": "...", "data": null } }
```

프론트의 `src/api/client.ts` 가 이 래퍼를 벗겨 `ApiResult<T>` 로 돌려준다.

## 엔드포인트

> 형식 — 엔드포인트마다 아래 표를 하나씩 추가한다.
>
> ### `<METHOD> <경로>` — 한 줄 설명
>
> | 구분 | 필드 | 타입 | nullable | 설명 |
> |---|---|---|---|---|
> | 요청 | | | | |
> | 응답 | | | | |
>
> 상태코드: 200 … / 400 … / 404 …

### `GET /api/v1/todos` — 할 일 목록 (최신순)

| 구분 | 필드 | 타입 | nullable | 설명 |
|---|---|---|---|---|
| 요청 | (없음) | | | |
| 응답 | `[].id` | number | X | 할 일 식별자 |
| 응답 | `[].title` | string | X | 제목 |
| 응답 | `[].done` | boolean | X | 완료 여부 |
| 응답 | `[].createdAt` | string | X | 생성 시각. `2026-09-03T17:12:18.744056` 꼴의 지역 시각(타임존 없음, 소수점 이하 있음 — 실호출로 확인) |

상태코드: 200

### `POST /api/v1/todos` — 할 일 등록

| 구분 | 필드 | 타입 | nullable | 설명 |
|---|---|---|---|---|
| 요청 | `title` | string | X | 1~200자. 앞뒤 공백은 서버가 지운다 |
| 응답 | | | | `GET` 의 항목 하나와 같다 |

상태코드: 201 / 400 `INVALID_REQUEST` (필드별 사유는 `error.data` 에 `[{field, message}]`)

### `PUT /api/v1/todos/{todoId}` — 할 일 전체 교체

| 구분 | 필드 | 타입 | nullable | 설명 |
|---|---|---|---|---|
| 요청 | `title` | string | X | 1~200자 |
| 요청 | `done` | boolean | X | 완료 여부 |
| 응답 | | | | `GET` 의 항목 하나와 같다 |

상태코드: 200 / 400 `INVALID_REQUEST` / 404 `TODO_NOT_FOUND`

### `DELETE /api/v1/todos/{todoId}` — 할 일 삭제

| 구분 | 필드 | 타입 | nullable | 설명 |
|---|---|---|---|---|
| 요청 | (없음) | | | 대상은 경로 식별자로 고른다 |
| 응답 | (없음) | | | 본문 없음 |

상태코드: 204 / 404 `TODO_NOT_FOUND`
