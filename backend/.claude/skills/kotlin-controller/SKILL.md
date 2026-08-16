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
        @Valid @RequestBody request: TodoCreateRequestDto,
    ): ApiResponse<TodoResponse> {
        val result: TodoResult = todoService.create(member.id, request.toCommand())
        return ApiResponse.success(TodoResponse.from(result))
    }
}
```

## 규칙

- 생성자 주입만 쓴다. `@Autowired` 필드 주입 금지.

- 경로는 `/api/v1/<복수형>` 으로 버저닝한다.

- HTTP 동사 의미론을 지킨다: 조회 GET, 생성 POST, 전체 교체 PUT, 부분 변경 PATCH, 삭제 DELETE. 조회를 POST 로 하지 않고, 상태를 바꾸는 GET 을 만들지 않는다.

- 요청 본문은 `@Valid` 를 붙여 검증한다.

- 예외를 `try/catch` 로 잡지 않는다. `ApiControllerAdvice` 가 한 곳에서 상태코드로 번역한다.

- 엔티티를 반환하거나 파라미터로 받지 않는다.

- 컨트롤러에서 리포지토리·구현 레이어를 직접 부르지 않는다. 도메인 서비스만 부른다.

- 응답은 항상 응답 DTO 로 감싼다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 엔티티를 반환하거나 파라미터로 받음 | 저장소 격리 붕괴 | Critical |
| 리포지토리·구현 레이어 직접 호출 | 레이어 건너뛰기 | Critical |
| 컨트롤러 안 업무 규칙 분기 | 책임 침범 | Critical |
| 컨트롤러의 `try/catch` | 예외 처리 중복·누락 | Critical |
| `@RequestBody` 에 `@Valid` 누락 | 검증 우회 | Critical |
| 상태를 바꾸는 GET / 조회용 POST | HTTP 의미론 위반 | Critical |
| 버전 없는 경로 | 클라이언트 파손 위험 | Important |
| 필드 주입 | 테스트·불변성 저해 | Important |
| 응답 DTO 로 감싸지 않은 응답 | 응답 형식 불일치 | Important |

## 체크리스트

- [ ] 변환·인증추출·위임 외의 로직이 없는가

- [ ] 엔티티가 시그니처에 없는가

- [ ] `@Valid` 와 버전 경로가 있는가

- [ ] 도메인 서비스만 참조하는가
