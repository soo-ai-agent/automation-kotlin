# API 계약

> **이 문서는 에이전트가 씁니다.** `api` 노드가 여기에 적고, `web` 노드가 읽어 화면을 만듭니다. 사람이 직접 고칠 일은 없습니다 — 계약이 잘못됐으면 `web` 노드가 아래에 문제를 적어 둡니다.

아직 기록된 엔드포인트가 없다. `api` 노드가 첫 API 를 만들면 여기에 추가된다.

## 응답 래퍼

모든 응답은 `ApiResponse<T>` 로 감싸진다 (`core-api` 의 `support/response/ApiResponse.kt`). 아래 엔드포인트 표에는 **`data` 안쪽의 모양**만 적는다.

```json
{ "result": "SUCCESS", "data": { }, "error": null }
{ "result": "ERROR",   "data": null, "error": { "code": "...", "message": "...", "data": null } }
```

프론트의 `src/lib/apiClient.ts` 가 이 래퍼를 벗겨 `ApiResult<T>` 로 돌려준다.

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

(아직 없음)
