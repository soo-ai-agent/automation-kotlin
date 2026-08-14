# 백엔드 코딩 규칙 스킬

> **이 폴더는 에이전트가 읽습니다.** `backend/` 아래 파일을 고칠 때 자동으로 적용됩니다.

Kotlin + Spring Boot 멀티모듈 백엔드의 규칙이다. 스택과 무관한 공통 규칙은 [`.claude/skills/`](../../../.claude/skills/) 에 있다.

**16종을 다 읽지 않는다.** 아래 "항상" 셋을 읽고, 나머지는 지금 고치는 파일이 무엇인지에 따라 골라 읽는다.

## 항상

| 스킬 | 다루는 것 |
|---|---|
| [kotlin-common](kotlin-common/SKILL.md) | 2대 원칙, 자료형, 불변성, 조건문 풀어쓰기, 이름, 예외, 주석, 검증 |
| [kotlin-module-layout](kotlin-module-layout/SKILL.md) | 새 파일을 어느 모듈·패키지에 둘지, 의존 방향, 도메인 경계 |
| [kotlin-test](kotlin-test/SKILL.md) | 한 메서드 = 한 기능, MockK 범위, 계층별 테스트 대상 |

## 기능 하나를 만들 때 — 아래에서 위로

새 도메인은 이 순서로 만든다. 아래에서 위로 쌓아야 상위 계층이 이미 있는 것을 조립하게 된다.

| # | 스킬 | 언제 |
|---|---|---|
| 1 | [kotlin-entity](kotlin-entity/SKILL.md) | 테이블·상태 변경 — `@Entity`, `protected set` + 행위 메서드, 애그리게이트 |
| 2 | [kotlin-migration](kotlin-migration/SKILL.md) | **엔티티를 바꾸면 반드시 함께** — Flyway 파일 이름·자리, 무중단 배포 순서 |
| 3 | [kotlin-repository](kotlin-repository/SKILL.md) | 쿼리 추가, 느린 쿼리 — 메서드 이름, 페이징, fetch join 과 N+1 |
| 4 | [kotlin-implement](kotlin-implement/SKILL.md) | 조회·저장 상세 — `Finder`·`Appender` 재사용 단위, 엔티티↔도메인 변환 |
| 5 | [kotlin-domain-service](kotlin-domain-service/SKILL.md) | 업무 흐름 — 유스케이스 조립, `@Transactional` 경계 |
| 6 | [kotlin-dto](kotlin-dto/SKILL.md) | 요청·응답 형태 — `RequestDto`·`ResponseDto` 이름 규약, 검증 애너테이션 |
| 7 | [kotlin-controller](kotlin-controller/SKILL.md) | 엔드포인트 — `@RestController`, `ApiResponse` 래핑, 인증 정보 추출 |

## 상황에 따라

| 스킬 | 언제 |
|---|---|
| [kotlin-error](kotlin-error/SKILL.md) | 실패 분기를 만들 때 — `ErrorCode`·`ErrorType`·`CoreException`, 상태코드·로그 레벨 |
| [kotlin-auth](kotlin-auth/SKILL.md) | 로그인·권한·"내 것만 조회" — 소유자 스코프, 401·403·404 구분 |
| [kotlin-client](kotlin-client/SKILL.md) | 외부 API 연동 — `clients/client-*`, `internal` 캡슐화, 타임아웃 |
| [kotlin-config](kotlin-config/SKILL.md) | 설정값·접속 정보·API 키 — 모듈별 yml, 프로파일 5종, 비밀값 주입 |
| [kotlin-logging](kotlin-logging/SKILL.md) | 로그를 남길 때 — 레벨 기준, `{}` 치환, 넣으면 안 되는 것 |
| [kotlin-api-docs](kotlin-api-docs/SKILL.md) | 외부가 쓰는 API 를 문서화할 때 — REST Docs, `index.adoc` |

## 문서 구조

스킬 16종 모두 같은 모양이다. 마지막 두 절만 봐도 리뷰는 된다.

- **규칙** — 지켜야 할 것

- **적발 신호** — 리뷰에서 잡아낼 패턴. `Critical` 은 머지 차단 사유이고, `Important` 는 참고 코멘트로만 남는다

- **체크리스트** — 작업을 끝내기 전 확인할 것

머지를 막는 기준 전체는 [common/docs/code-review/rules.md](../../../common/docs/code-review/rules.md) 에 있다.
