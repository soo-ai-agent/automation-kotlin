# backend

Kotlin + Spring Boot 멀티모듈 백엔드다. **뼈대와 첫 도메인(`todo`)이 이미 들어 있어 바로 뜬다.**

뼈대는 [team-dodn/spring-boot-kotlin-template](https://github.com/team-dodn/spring-boot-kotlin-template) 에서 가져와,
이 저장소의 배치 규칙(`.claude/skills/kotlin-module-layout`)대로 부팅과 도메인을 나눈 것이다.

**JDK 25 가 필요하다** — `gradle.properties` 의 `javaVersion=25` 가 툴체인을 요구하고, CI 도 Temurin 25 를 쓴다.

## 확인과 실행

```bash
cd backend
./gradlew ktlintCheck unitTest     # 에이전트의 기본 검증선
./gradlew :api:bootRun             # 8080 으로 뜬다. 다른 포트는 --args='--server.port=18080'
```

| 태스크 | 언제 |
|---|---|
| `ktlintCheck` / `ktlintFormat` | 항상. 실패하면 format 후 다시 확인 |
| `unitTest` | 항상. 결과 XML 은 `<모듈>/build/test-results/unitTest/` 에 쌓인다 |
| `contextTest` | 스프링 컨텍스트가 필요할 때 (에이전트는 안 돌린다) |
| `restDocsTest` | API 문서 생성 (에이전트는 안 돌린다) |
| `:api:bootJar` | 배포 이미지 빌드 |

`local` 프로파일이 기본이라 네트워크 없이 뜬다 — H2 메모리 DB 에 `ddl-auto: create` 이고 Flyway 는 꺼져 있다.

## 모듈 배치

```
api/                  부팅 전용 — ApiApplication, ApiControllerAdvice, AsyncConfig, HealthController
core/core-common/     둘 이상의 도메인이 쓰는 것만 — ApiException 베이스, ApiResponse
core/core-enum/       여러 모듈이 공유하는 enum (아직 비어 있다)
core/core-todo/       첫 도메인 통째로 — api/ + domain/
storage/db-core/      엔티티·리포지토리·마이그레이션
support/logging/      로그 설정
support/monitoring/   액추에이터·메트릭
tests/api-docs/       RestDocs 테스트 베이스
```

외부 시스템을 붙이면 `clients/client-<이름>/` 을 만든다 (`kotlin-client`). 지금은 붙인 것이 없어 모듈도 없다.

패키지 루트는 `io.automation` 이다 — 스킬 문서의 예시 경로(`io.dodn.springboot`)는 이것으로 바꿔 읽는다.

## 첫 도메인 `todo` 가 각 레이어의 표준 형태다

새 도메인은 이 파일들을 복사해 이름만 바꾸는 것으로 시작한다. 규칙과 코드가 어긋나면 **코드가 맞다.**

| 레이어 | 파일 | 무엇을 보여주나 |
|---|---|---|
| 엔티티 | `storage/db-core/.../TodoEntity.kt` | `protected set` + 행위 메서드(`rename`·`complete`·`reopen`), `require` 불변식 |
| 마이그레이션 | `storage/db-core/src/main/resources/db/migration/` | `V<YYYYMMDDHHmm>__<설명>.sql` |
| 리포지토리 | `storage/db-core/.../TodoRepository.kt` | 파생 쿼리. `findByIdOrNull` 대신 `findOneById` |
| 도메인 모델 | `core-todo/domain/model/` | `Result`·`Command`, 전부 `val` |
| 예외 | `core-todo/domain/error/` | 던지는 도메인이 소유. 자기 status·code 를 갖는다 |
| 구현 레이어 | `core-todo/domain/service/Todo{Finder,Appender,Updater,Remover}.kt` | 역할 하나씩. 엔티티↔모델 변환은 `TodoEntityMapper.kt` 한 곳 |
| 도메인 서비스 | `core-todo/domain/service/TodoService.kt` | 흐름 조립과 트랜잭션 경계만 |
| DTO | `core-todo/api/request/`·`api/response/` | `@field:` 검증, `toCommand()`·`from()` |
| 컨트롤러 | `core-todo/api/controller/TodoController.kt` | 변환·위임만. 201·204 상태코드 |
| 테스트 | 각 모듈 `src/test/` | 한 메서드가 한 기능. 백틱 한글 이름 |

만드는 순서는 위에서 아래로다 — `core-enum` → 엔티티 + 마이그레이션 → 리포지토리 → 도메인 모델 → 구현 레이어 → 도메인 서비스 → DTO → 컨트롤러.

파일을 어디에 둘지는 `.claude/skills/kotlin-module-layout/SKILL.md` 의 배치표가 정본이다.

## 뼈대에 이미 반영해 둔 것

템플릿 그대로 두면 걸리는 자리들이다. 다시 만들 필요는 없고, 왜 이렇게 되어 있는지만 알아 두면 된다.

- **검증 의존성** — `core/core-todo/build.gradle.kts` 에 `spring-boot-starter-validation` 이 있다.
  요청 DTO 가 있는 모듈에 둔다. 없으면 `@field:NotBlank` 가 `Unresolved reference` 로 깨진다.

- **검증 실패 응답** — `ApiControllerAdvice` 가 `MethodArgumentNotValidException` 을 `RequestValidationException` 으로 옮겨
  `ApiResponse` 형태로 내보낸다. 없으면 400 이 스프링 기본 응답으로 나가 프론트 `apiClient` 가 래퍼를 벗기지 못한다.

- **깨진 본문** — `HttpMessageNotReadableException` 핸들러가 없으면 400 이 아니라 500 이 나간다.

- **Flyway** — `storage/db-core` 에 있고 `local` 프로파일에서만 꺼져 있다. 운영은 `ddl-auto: validate` 라
  엔티티를 바꾸면 **같은 커밋에 마이그레이션이 있어야** 부팅한다.

- **`storage:db-core` → `core:core-enum` 의존** — 엔티티의 enum 컬럼이 공유 enum 일 때 필요하다.
  storage 가 올려다볼 수 있는 유일한 core 모듈이다.

- **`client-example.yml` import 제거** — 예시 클라이언트 모듈을 안 가져왔으므로 `application.yml` 의 import 도 없다.

## 응답 형식

응답은 항상 `ApiResponse<T>` 로 감싼다 — `{result, data, error}`. 새 엔드포인트를 만들면 저장소 루트
[CONTRACT.md](../CONTRACT.md) 에 계약을 기록한다. 프론트가 그 문서를 보고 화면을 만든다.

에러는 `error: {code, message, data}` 이고, 검증 실패면 `data` 에 `[{field, message}]` 가 담긴다.

## 배포 전에

- 이미지는 [Dockerfile](Dockerfile) 로 빌드한다. `bootJar` 산출물을 담기만 하므로 `./gradlew :api:bootJar` 가 먼저다 (CI 가 알아서 한다).

- DB 접속 정보처럼 환경마다 달라지는 값은 배포 환경변수로 준다 (`.claude/skills/kotlin-config`).
