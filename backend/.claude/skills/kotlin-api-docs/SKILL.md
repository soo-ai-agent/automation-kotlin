---
name: kotlin-api-docs
description: Spring REST Docs 로 API 문서를 만드는 규칙. restdocs 태그 테스트의 자리와 형태, RestDocsTest 상속, 스니펫 이름 규약, index.adoc 에 include 추가, CONTRACT.md 와의 관계를 다룬다. 엔드포인트를 추가·변경할 때 kotlin-controller 와 함께 사용한다. "API 문서", "RestDocs", "문서 테스트" 요청에도 사용할 것.
---

# API 문서 테스트 (Spring REST Docs)

**자리:** 테스트는 `core/core-<도메인>/src/test/.../api/controller/XxxControllerTest.kt`, 문서는 `core/core-<도메인>/src/docs/asciidoc/index.adoc`

## 문서를 손으로 쓰지 않는다

REST Docs 는 **테스트를 실제로 돌려서** 요청·응답 조각(스니펫)을 뽑고, 그것을 문서에 끼워 넣는다.

그래서 문서가 코드와 어긋날 수 없다 — 응답 필드가 바뀌면 **문서 테스트가 먼저 실패한다.** 문서를 고치는 것이 아니라 문서 테스트가 깨져서 알려주는 구조다.

```
XxxControllerTest 실행 → build/generated-snippets/<식별자>/*.adoc 생성
                       → index.adoc 이 include → asciidoctor 가 HTML 로
```

`./gradlew asciidoctor` 는 `restDocsTest` 를 먼저 돌리도록 이미 연결돼 있다.

## 컨트롤러 테스트가 곧 문서 테스트다

`RestDocsTest` 를 상속하면 `@Tag("restdocs")` 가 함께 붙어 `restDocsTest` 태스크에만 잡힌다. `unitTest` 에서는 제외된다.

스프링 컨텍스트를 띄우지 않고 `mockController(...)` 로 컨트롤러 하나만 세운다. 그래서 빠르다.

```kotlin
class TodoControllerTest : RestDocsTest() {
    private lateinit var todoService: TodoService

    @BeforeEach
    fun setUp() {
        todoService = mockk()
        mockMvc = mockController(TodoController(todoService))
    }

    @Test
    fun create() {
        every { todoService.create(any(), any()) } returns TodoResult(1L, "장보기", false, LocalDateTime.now())

        mockMvc.perform(
            post("/api/v1/todos")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonMapper().writeValueAsString(TodoCreateRequestDto("장보기"))),
        )
            .andExpect(status().isOk)
            .andDo(
                document(
                    "todoCreate",
                    Preprocessors.preprocessRequest(Preprocessors.prettyPrint()),
                    Preprocessors.preprocessResponse(Preprocessors.prettyPrint()),
                    requestFields(
                        fieldWithPath("title").type(JsonFieldType.STRING).description("할 일 제목"),
                    ),
                    responseFields(
                        fieldWithPath("result").type(JsonFieldType.STRING).description("SUCCESS 또는 ERROR"),
                        fieldWithPath("data.id").type(JsonFieldType.NUMBER).description("할 일 식별자"),
                        fieldWithPath("data.title").type(JsonFieldType.STRING).description("제목"),
                        fieldWithPath("data.done").type(JsonFieldType.BOOLEAN).description("완료 여부"),
                        fieldWithPath("data.createdAt").type(JsonFieldType.STRING).description("생성 시각"),
                        fieldWithPath("error").type(JsonFieldType.NULL).ignored(),
                    ),
                ),
            )
    }
}
```

- 서비스는 `mockk()` 로 세운다. 문서 테스트는 **컨트롤러의 입출력 모양**을 검증하는 것이지 업무 규칙을 검증하는 것이 아니다.

- `document()` 의 첫 인자가 **스니펫 폴더 이름**이다. `<도메인><동작>` 카멜케이스로 쓴다 (`todoCreate`, `todoList`, `todoDelete`). 이 이름으로 `index.adoc` 에서 끌어 쓴다.

- **응답 필드를 하나라도 빠뜨리면 테스트가 실패한다.** 응답 DTO 껍데기의 `result`·`error` 까지 전부 적는다. 쓰지 않는 필드는 `.ignored()`.

- 경로 변수는 `pathParameters`, 쿼리는 `queryParameters` 로 함께 문서화한다.

## 문서에 끼워 넣기

스니펫만 만들면 아무 데도 안 나온다. `index.adoc` 에 절을 추가해야 보인다.

```asciidoc
== Todo API

=== 할 일 등록
==== Curl Request
include::{snippets}/todoCreate/curl-request.adoc[]
==== Request Fields
include::{snippets}/todoCreate/request-fields.adoc[]
==== Http Response
include::{snippets}/todoCreate/http-response.adoc[]
==== Response Fields
include::{snippets}/todoCreate/response-fields.adoc[]
```

`{snippets}` 는 파일 머리에 `:snippets: build/generated-snippets` 로 이미 정의돼 있다.

## CONTRACT.md 와 무엇이 다른가

| | `CONTRACT.md` | REST Docs |
|---|---|---|
| 누가 쓰나 | `api` 노드가 손으로 | 테스트 실행이 자동으로 |
| 누가 읽나 | `web` 노드 (같은 작업 안에서 바로) | 사람 — 프론트 개발자·외부 연동 |
| 언제 | API 를 만든 직후 | 배포 문서가 필요할 때 |

**둘 다 필요하다.** `CONTRACT.md` 는 그래프 안에서 `api` → `web` 으로 넘기는 쪽지라 즉시성이 중요하고, REST Docs 는 오래 남는 문서라 정확성이 중요하다.

둘이 어긋나면 **REST Docs 가 맞다** — 실제로 실행해서 뽑은 것이기 때문이다.

## 언제 쓰나

`e2e`·`test` 노드는 이 테스트를 돌리지 않는다 (`restdocs` 태그는 `unitTest` 에서 제외된다). 그래서 **CI 기본 검증에 걸리지 않는다.**

공개 API 이거나 프론트가 아닌 외부가 쓰는 API 면 문서 테스트를 함께 만든다. 내부에서만 쓰고 곧 바뀔 API 면 `CONTRACT.md` 만으로 충분하다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 응답 필드 일부만 문서화 | 테스트 실패 — 빠진 필드가 있으면 REST Docs 가 거부한다 | Critical |
| `RestDocsTest` 를 상속하지 않고 `@SpringBootTest` 사용 | `restdocs` 태그가 안 붙고 느려진다 | Critical |
| 문서 테스트에서 실제 서비스·리포지토리 사용 | 문서 테스트가 통합 테스트로 변질 | Important |
| 스니펫만 만들고 `index.adoc` 에 include 누락 | 문서에 안 나옴 | Important |
| 스니펫 이름이 중복되거나 도메인·동작을 안 드러냄 | 문서에서 찾을 수 없음 | Important |
| `description` 이 필드명 반복 (`"title"` → `"title"`) | 문서로서 가치 없음 | Important |

## 체크리스트

- [ ] `RestDocsTest` 를 상속하고 서비스는 `mockk()` 인가

- [ ] 응답 DTO 껍데기(`result`·`error`)까지 모든 응답 필드를 적었는가

- [ ] 스니펫 이름이 `<도메인><동작>` 이고 중복되지 않는가

- [ ] `index.adoc` 에 include 절을 추가했는가

- [ ] `./gradlew restDocsTest asciidoctor` 가 통과하는가
