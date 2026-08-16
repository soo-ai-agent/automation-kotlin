---
name: kotlin-config
description: 설정과 비밀값 규칙. 모듈별 yml 파일의 소유와 spring.config.import, 프로파일 5종(local·local-dev·dev·staging·live)의 역할, 비밀값을 코드·저장소에 두지 않고 환경변수로 주입하는 법, @ConfigurationProperties 로 타입 있게 읽는 법을 다룬다. 설정값·접속 정보·외부 주소를 추가할 때 사용한다. "설정 추가", "환경별로 다르게", "API 키" 요청에도 사용할 것.
---

# 설정과 비밀값

**자리:** 설정은 그 값을 쓰는 **모듈의 `src/main/resources/<모듈>.yml`**, 비밀값은 **저장소 밖**

## 설정 파일은 모듈이 소유한다

부팅 모듈이 모든 설정을 갖지 않는다. 각 모듈이 자기 설정 파일을 갖고, 부팅 모듈 `api` 가 그것을 끌어다 합친다.

```yaml
# core/core-<도메인>/src/main/resources/application.yml
spring:
  config:
    import:
      - monitoring.yml
      - logging.yml
      - db-core.yml
      - client-example.yml
```

| 무엇을 설정하나 | 어느 파일 |
|---|---|
| DB 접속·JPA·커넥션 풀 | `storage/db-core/.../db-core.yml` |
| 외부 API 주소·타임아웃 | `clients/client-<이름>/.../client-<이름>.yml` |
| 로그 레벨·포맷 | `support/logging/.../logging.yml` |
| 액추에이터·메트릭 | `support/monitoring/.../monitoring.yml` |
| 서버 포트·스레드 등 앱 전역 | `core/core-<도메인>/.../application.yml` |

**새 모듈을 만들면 그 모듈의 yml 을 만들고 `application.yml` 의 `import` 에 한 줄 추가한다.** 빠뜨리면 설정이 조용히 무시된다.

## 프로파일 다섯 개

한 yml 파일 안에서 `---` 로 나누고 `spring.config.activate.on-profile` 로 구분한다. 공통값을 맨 위에 두고 아래에서 덮어쓴다.

| 프로파일 | 무엇을 위한 것 | DB |
|---|---|---|
| `local` | **네트워크 없이** 개발. 기본값 | H2 메모리 |
| `local-dev` | 내 컴퓨터에서 dev 환경 DB 에 붙어 개발 | dev MySQL |
| `dev` | 개발 서버 배포 | dev MySQL |
| `staging` | 검증 서버 배포 | staging MySQL |
| `live` | 운영 배포 | live MySQL |

```yaml
spring:
  jpa:
    open-in-view: false      # 모든 프로파일 공통

---
spring.config.activate.on-profile: local

spring:
  jpa:
    hibernate:
      ddl-auto: create       # local 만 덮어쓴다
```

**값을 추가할 때는 "어느 프로파일에 필요한가"를 먼저 정한다.** 전부 같으면 공통 절에만 쓴다. 프로파일마다 같은 값을 복사해 두면 하나만 고치고 나머지를 잊는다.

`local` 은 오프라인에서 떠야 한다 — 외부 주소나 실제 자격 증명을 `local` 절에 넣지 않는다.

## 비밀값은 저장소에 없다

**비밀번호·토큰·API 키를 yml 에 값으로 적지 않는다.** 자리만 만들고 값은 밖에서 넣는다.

```yaml
storage:
  datasource:
    core:
      jdbc-url: jdbc:mysql://${storage.database.core-db.url}
      username: ${storage.database.core-db.username}
      password: ${storage.database.core-db.password}
```

`${...}` 는 환경변수나 배포 시크릿에서 채워진다. 대응하는 환경변수 이름은 점을 밑줄로, 대문자로 바꾼 것이다 — `STORAGE_DATABASE_CORE_DB_PASSWORD`.

이 프로젝트에서 실제로 넣는 곳은 서버의 `docker-compose.yml` `environment` 절이다 (`docs/deploy.md`).

기본값을 주고 싶으면 `${VAR:기본값}` 을 쓰되, **비밀값에는 기본값을 주지 않는다.** 설정이 빠진 채 뜨는 것보다 못 뜨는 것이 낫다.

- 커밋 전에 `git diff` 로 값이 딸려 들어가지 않았는지 본다.

- 실수로 커밋했다면 **값을 지우는 것으로 끝나지 않는다.** 이력에 남으므로 그 자격 증명을 폐기하고 새로 발급한다.

- 로그·예외 메시지·API 응답에도 넣지 않는다 (`kotlin-error`).

## 코드에서 읽을 때 — 타입을 붙인다

`@Value("\${...}")` 를 여기저기 흩뿌리지 않는다. 관련된 값은 한 클래스로 묶어 `@ConfigurationProperties` 로 받는다.

```kotlin
@ConfigurationProperties(prefix = "example.api")
data class ExampleApiProperties(
    val url: String,
    val timeoutMillis: Int = 3000,
)
```

- **타입이 붙어 오타와 형변환 오류를 뜰 때 잡는다.** 문자열로 흩어 두면 실행 중에 터진다.

- 값이 없으면 못 뜨게 하려면 기본값을 주지 않는다.

- 설정을 읽는 클래스는 그 설정을 쓰는 모듈에 둔다. 다른 모듈의 설정을 직접 읽지 않는다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| yml·코드에 비밀번호·토큰·키의 실제 값 | 저장소 이력에 영구히 남는 유출 | Critical |
| 비밀값에 `${VAR:기본값}` 으로 기본값 부여 | 설정 누락을 모른 채 잘못된 값으로 기동 | Critical |
| `local` 프로파일에 실제 외부 주소·자격 증명 | 오프라인 개발 불가, 유출 경로 | Critical |
| 새 모듈 yml 을 만들고 `import` 에 추가 안 함 | 설정이 조용히 무시됨 | Important |
| 프로파일마다 같은 값을 복사 | 하나만 고치고 나머지를 잊음 | Important |
| `@Value` 를 여러 클래스에 흩뿌림 | 타입 없음, 어디서 쓰는지 추적 불가 | Important |
| 다른 모듈의 설정 키를 직접 읽음 | 모듈 경계 침범 | Important |

## 체크리스트

- [ ] 설정을 그 값을 쓰는 모듈의 yml 에 뒀는가

- [ ] 새 yml 이면 `application.yml` 의 `import` 에 추가했는가

- [ ] 어느 프로파일에 필요한 값인지 정하고, 공통은 공통 절에만 뒀는가

- [ ] 비밀값이 `${...}` 자리만 있고 실제 값이 없는가 (기본값도 없는가)

- [ ] 코드에서 읽는다면 `@ConfigurationProperties` 로 타입을 붙였는가
