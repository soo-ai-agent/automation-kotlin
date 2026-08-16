---
name: kotlin-controller
description: 컨트롤러 작성과 리뷰 규칙. core-<도메인> 의 controller 패키지, @RestController, 요청/응답 변환, 인증 정보 추출, 응답 DTO 래핑, HTTP 동사와 상태코드를 다룰 때 사용한다. "엔드포인트 추가", "API 만들어줘" 요청에도 사용할 것.
---

# Controller

**자리:** `core/core-<도메인>/.../<도메인>/api/controller/XxxController.kt`

## 하는 일은 셋뿐

1. 요청 DTO → 도메인 입력 모델 변환 (변환 메서드는 DTO 가 가진다)

2. 인증 정보 추출 (`@AuthenticationPrincipal` 등)

3. 도메인 결과 → 응답 DTO 변환 후 `ApiResponse` 로 감싸기.
   **래퍼는 프론트 계약이다**(`CONTRACT.md` 의 `{result, data, error}`) — 벗기면 프론트 `apiClient` 가 못 읽는다

그 밖의 판단은 전부 도메인 서비스의 몫이다. 컨트롤러에 `if` 로 된 업무 규칙이 보이면 위반이다.

```kotlin
@RestController
@RequestMapping("/api/v1/todos")
class TodoController(
    private val todoService: TodoService,
) {
    @GetMapping
    fun list(@AuthenticationPrincipal member: MemberPrincipal): ApiResponse<List<TodoResponse>> {
        val results: List<TodoResult> = todoService.list(member.id)
        return ApiResponse.success(results.map(TodoResponse::from))
    }

    @PostMapping
    fun create(
        @AuthenticationPrincipal member: MemberPrincipal,
        @Valid @RequestBody request: TodoCreateRequest,
    ): ApiResponse<TodoResponse> {
        val result: TodoResult = todoService.create(member.id, request.toCommand())
        return ApiResponse.success(TodoResponse.from(result))
    }
}
```

## 규칙

- 생성자 주입만 쓴다. `@Autowired` 필드 주입 금지.

- 경로는 `/api/v1/<복수형>` 으로 버저닝한다. 나머지 경로 규약은 아래 "URL 은 REST 를 지킨다" 를 따른다.

- HTTP 동사 의미론을 지킨다: 조회 GET, 생성 POST, 전체 교체 PUT, 부분 변경 PATCH, 삭제 DELETE. 조회를 POST 로 하지 않고, 상태를 바꾸는 GET 을 만들지 않는다.

- 요청 본문은 `@Valid` 를 붙여 검증한다.

- 예외를 `try/catch` 로 잡지 않는다. `ApiControllerAdvice` 가 한 곳에서 상태코드로 번역한다.

- 엔티티를 반환하거나 파라미터로 받지 않는다.

- 컨트롤러에서 리포지토리·구현 레이어를 직접 부르지 않는다. 도메인 서비스만 부른다.

- 응답은 항상 응답 DTO 로 감싼다.

## URL 은 REST 를 지킨다

**경로는 자원을 가리키고, 행위는 HTTP 동사가 말한다.** 경로에 동사가 들어갔다면 그 동사는 이미 메서드 자리에 있어야 할 말이다.

| 규칙 | X | O |
|---|---|---|
| 자원은 복수형 명사 | `/api/v1/user` `/api/v1/getUser` | `/api/v1/users` |
| 행위는 경로가 아니라 메서드로 | `POST /api/v1/users/create` | `POST /api/v1/users` |
| 삭제도 메서드로 | `POST /api/v1/users/1/delete` | `DELETE /api/v1/users/1` |
| 단건은 식별자로 | `GET /api/v1/users/findById?id=1` | `GET /api/v1/users/1` |
| 걸러 보기는 질의 문자열로 | `GET /api/v1/users/active` | `GET /api/v1/users?status=active` |
| 소속은 중첩으로 | `GET /api/v1/orderItems?orderId=1` | `GET /api/v1/orders/1/items` |
| 낱말 구분은 하이픈 | `/api/v1/orderItems` `/api/v1/order_items` | `/api/v1/order-items` |

**중첩은 한 겹까지.** `/orders/1/items/2/options` 처럼 깊어지면 아래 자원을 최상위로 올린다 — `/order-items/2/options`. 식별자가 이미 유일하면 부모를 경로에 다시 쓸 이유가 없다.

**상태코드도 계약이다.** 생성은 201, 본문 없는 삭제는 204, 나머지 성공은 200. 실패를 200 으로 내리지 않는다.

**동사를 도저히 뺄 수 없는 요청**(검색·일괄 처리처럼 자원 하나로 안 떨어지는 것)은 그 행위를 **자원으로 이름 붙인다** — `POST /api/v1/searches` 처럼. 그래도 안 되면 예외임을 컨트롤러에 한 줄로 남긴다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 엔티티를 반환하거나 파라미터로 받음 | 저장소 격리 붕괴 | Critical |
| 리포지토리·구현 레이어 직접 호출 | 레이어 건너뛰기 | Critical |
| 컨트롤러 안 업무 규칙 분기 | 책임 침범 | Critical |
| 컨트롤러의 `try/catch` | 예외 처리 중복·누락 | Critical |
| `@RequestBody` 에 `@Valid` 누락 | 검증 우회 | Critical |
| 상태를 바꾸는 GET / 조회용 POST | HTTP 의미론 위반 | Critical |
| 경로에 동사(`/create`·`/getUser`·`/delete`) | HTTP 동사와 중복 — REST 위반 | Critical |
| 자원이 단수·camelCase (`/user`·`/orderItems`) | 경로 규약 불일치 | Important |
| 중첩 두 겹 이상 | 결합된 경로 — 상위 자원 변경에 끌려간다 | Important |
| 버전 없는 경로 | 클라이언트 파손 위험 | Important |
| 필드 주입 | 테스트·불변성 저해 | Important |
| 응답 DTO 로 감싸지 않은 응답 | 응답 형식 불일치 | Important |

## 체크리스트

- [ ] 변환·인증추출·위임 외의 로직이 없는가

- [ ] 엔티티가 시그니처에 없는가

- [ ] `@Valid` 와 버전 경로가 있는가

- [ ] 경로가 복수형 명사이고 동사가 없는가 (하이픈 표기, 중첩 한 겹)

- [ ] 도메인 서비스만 참조하는가
