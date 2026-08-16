# backend

백엔드 앱이 들어갈 자리다. Kotlin + Spring Boot 멀티모듈을 쓴다.

**지금 이 폴더는 거의 비어 있다.** 에이전트가 따를 코딩 규칙(`.claude/skills/`)과 배포용 `Dockerfile` 만 있고, 실제 Spring 모듈은 없다.

아래 1~5 를 따라 뼈대를 채우고 커밋해야 `api` 노드가 백엔드를 만들 수 있다. 한 번만 하면 된다.

**모든 명령은 이 폴더 안에서 실행한다.** JDK 25 가 필요하다 — 템플릿의 `gradle.properties` 가 `javaVersion=25` 로 툴체인을 요구한다.

## 1. 뼈대 가져오기

[team-dodn/spring-boot-kotlin-template](https://github.com/team-dodn/spring-boot-kotlin-template) 에서 가져온다.

```bash
cd backend
git clone --depth 1 https://github.com/team-dodn/spring-boot-kotlin-template.git /tmp/tpl
cp -r /tmp/tpl/core /tmp/tpl/storage /tmp/tpl/support /tmp/tpl/clients /tmp/tpl/tests .
cp /tmp/tpl/build.gradle.kts /tmp/tpl/settings.gradle.kts /tmp/tpl/gradle.properties .
cp -r /tmp/tpl/gradle /tmp/tpl/gradlew /tmp/tpl/gradlew.bat /tmp/tpl/.editorconfig .
rm -rf /tmp/tpl
```

`settings.gradle.kts` 의 `rootProject.name` 과 패키지 루트(`io.dodn.springboot`)를 프로젝트 이름에 맞게 바꾼다. 패키지 경로를 바꿨다면 스킬 문서의 예시 경로도 그에 맞춰 읽는다.

템플릿 루트의 `CLAUDE.md`·`AGENTS.md`·`README.md` 는 가져오지 않는다 — 저장소 루트의 것과 충돌한다.

### 1-2. 템플릿 모듈을 도메인 구조로 바꾼다

**템플릿은 `core:core-api` 한 덩이로 온다. 그대로 두지 않는다.**
이 저장소의 배치 규칙은 `kotlin-module-layout` 이고, 부팅과 도메인을 분리한다.

```
api/                       부팅 전용 — Application, ApiControllerAdvice, 전역 설정
core/core-<도메인>/         한 도메인 통째로 (api/ + domain/)
core/core-common/          둘 이상의 도메인이 쓰는 것만 — ApiException 베이스
core/core-enum/            여러 모듈이 공유하는 enum
storage/db-core/           엔티티·리포지토리
clients/client-*/          외부 연동 (RestClient)
support/*/                 로깅·모니터링·범용 함수
```

옮기는 순서:

1. 템플릿 `core/core-api` 를 `api` 로 이름을 바꾸고, **부팅과 전역 설정만 남긴다.**
2. 도메인 코드(컨트롤러·서비스·구현·DTO)는 첫 도메인 모듈 `core/core-<도메인>` 으로 옮긴다.
3. `support/error`·`support/response` 는 `core/core-common` 으로 옮긴다.
4. `settings.gradle.kts` 의 `include` 를 새 모듈 이름으로 고친다.

### 1-3. 모듈을 옮기고 나면 배선 셋이 어긋나 있다

**실제로 이 셋에 다 걸린다.** 컴파일이나 기동이 막히는 지점이라 미리 적어 둔다.

1. **`storage:db-core` 가 `core:core-enum` 을 의존하지 않는다.** 그런데 배치 규칙은 enum 을
   `core-enum` 에 두라고 한다. 엔티티가 그 enum 을 쓰는 순간 `Unresolved reference` 가 난다.
   `storage/db-core/build.gradle.kts` 에 `api(project(":core:core-enum"))` 을 더한다.

2. **`api/src/main/resources/application.yml` 이 `client-example.yml` 을 import 한다.**
   예시 클라이언트 모듈을 의존에서 빼면 기동이 `Config data resource ... does not exist` 로
   실패한다. 안 쓰는 import 줄을 지운다.

3. **`AsyncExceptionHandler` 가 템플릿 예외(`CoreException`)를 안다.** 예외 베이스를
   `ApiException` 으로 바꾸면 여기도 함께 고쳐야 컴파일된다.

**도메인이 아직 하나뿐이면 모듈을 미리 쪼개지 않는다.** 두 번째 도메인이 생길 때 나눈다 —
나눌 값이 있는지는 `kotlin-module-layout` 의 "바깥의 import 수" 로 판단한다.

## 2. 검증 의존성 추가

**이 한 줄을 반드시 넣는다.** 템플릿에는 Bean Validation 이 빠져 있는데, 이 저장소의 리뷰 규칙은 신뢰 경계 입력에 `@Valid` 와 `@field:` 검증을 **MUST** 로 요구한다.

넣지 않으면 에이전트가 `@field:NotBlank` 를 쓰는 순간 `Unresolved reference 'validation'` 으로 컴파일이 깨진다.

`api/build.gradle.kts` 의 `dependencies` 에 추가한다(부팅 모듈).

```kotlin
implementation("org.springframework.boot:spring-boot-starter-validation")
```

인증을 쓸 계획이면 `spring-boot-starter-security` 도 함께 넣는다 — 컨트롤러 규칙의 `@AuthenticationPrincipal` 이 그것을 전제한다. 인증이 없는 프로젝트면 넣지 않아도 된다.

**넣는다면 `SecurityFilterChain` 을 반드시 같이 만든다.** 의존성만 넣으면 모든 경로가 인증을 요구해 `/health` 와 `/actuator/prometheus` 가 401 이 되고, 배포된 컨테이너가 헬스체크 실패로 재시작을 반복한다.

설정 코드는 `.claude/skills/kotlin-auth/SKILL.md` 에 있다.

### 검증 실패 응답 핸들러

의존성만 넣으면 `@Valid` 가 걸리기는 하는데, 템플릿 `ApiControllerAdvice` 에는 검증 실패 예외 핸들러가 없다.

그래서 400 이 `ApiResponse` 형태가 아닌 스프링 기본 응답으로 나가고, 프론트의 `apiClient` 가 래퍼를 벗기지 못한다.

`ApiException` 베이스와 `MethodArgumentNotValidException` 핸들러를 넣는다(`kotlin-error`).

복사할 코드는 `.claude/skills/kotlin-error/SKILL.md` 의 "검증 실패 핸들러" 절에 있다.

## 3. 마이그레이션 도구 추가

운영 프로파일은 `ddl-auto: validate` 로 돈다. **엔티티와 실제 테이블이 다르면 애플리케이션이 뜨지 않는다.**

그런데 템플릿에는 스키마를 바꿀 수단이 없다. Flyway 를 넣는다.

```kotlin
// storage/db-core/build.gradle.kts
implementation("org.flywaydb:flyway-core")
runtimeOnly("org.flywaydb:flyway-mysql")
```

`local` 프로파일은 H2 메모리 DB 에 `ddl-auto: create` 라 마이그레이션을 돌릴 필요가 없다. `storage/db-core/src/main/resources/db-core.yml` 의 `local` 절에 한 줄을 더한다.

```yaml
spring:
  flyway:
    enabled: false
```

마이그레이션 파일은 `storage/db-core/src/main/resources/db/migration/` 에 둔다. 파일 이름과 작성 규칙은 `.claude/skills/kotlin-migration/SKILL.md` 에 있다.

## 4. 확인

```bash
./gradlew ktlintCheck unitTest
```

통과하면 뼈대가 정상이다.

| 태스크 | 언제 |
|---|---|
| `ktlintCheck` / `ktlintFormat` | 항상. 실패하면 format 후 다시 확인 |
| `unitTest` | 항상. 에이전트의 기본 검증선 |
| `contextTest` | 스프링 컨텍스트가 필요할 때 (에이전트는 안 돌린다) |
| `restDocsTest` | API 문서 생성 (에이전트는 안 돌린다) |
| `:api:bootJar` | 배포 이미지 빌드 |

## 5. 커밋해서 올리기

**에이전트는 push 된 코드만 본다.** 로컬에서 만든 뼈대는 올리기 전까지 에이전트에게 존재하지 않는다 — 첫 구축을 지시하기 전에 반드시 올린다.

```bash
git add -A
git commit -m "chore:백엔드 뼈대 추가"
git push
```

커밋 메시지는 `<type>:<제목>` 형식(콜론 뒤 공백 없음)을 쓴다 — 에이전트도 같은 형식을 쓴다.

`api` 노드는 시작할 때 `backend/settings.gradle.kts` 가 있는지 확인하고, 없으면 구조를 지어내지 않고 보고 후 중단한다.

## 6. 실행

```bash
./gradlew :api:bootRun
```

기본 포트는 8080 이다. 프론트엔드는 `frontend/.env` 로 이 주소를 가리킨다 — 서로 읽지 않는다.

## 7. 새 도메인을 추가할 때

파일을 어디에 두는지는 `.claude/skills/kotlin-module-layout/SKILL.md` 의 배치표를 본다. 만드는 순서는 위에서 아래로:

    core-enum → 엔티티 + 마이그레이션 → 리포지토리 → 도메인 모델 → 구현 레이어 → 도메인 서비스 → DTO → 컨트롤러

템플릿의 `Example*` 파일들이 각 레이어의 표준 형태다. 첫 도메인을 만든 뒤 지워도 된다.

## 8. 응답 형식

응답은 항상 `ApiResponse<T>` 로 감싼다. 새 엔드포인트를 만들면 저장소 루트 [CONTRACT.md](../CONTRACT.md) 에 계약을 기록한다 — 프론트가 그 문서를 보고 화면을 만든다.

## 배포 전에

- 이미지는 [Dockerfile](Dockerfile) 로 빌드한다. `bootJar` 산출물을 담기만 하므로 `./gradlew :api:bootJar` 를 먼저 실행해야 한다 (CI 가 알아서 한다).

- DB 접속 정보처럼 환경마다 달라지는 값은 배포 환경변수로 준다.
