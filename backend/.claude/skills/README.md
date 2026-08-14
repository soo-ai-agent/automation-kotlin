# 백엔드 코딩 규칙 스킬

> **이 폴더는 에이전트가 읽습니다.** `backend/` 아래 파일을 고칠 때 자동으로 적용됩니다.

Kotlin + Spring Boot 멀티모듈 백엔드의 계층별 규칙이다. 스택과 무관한 공통 규칙은 [`.claude/skills/`](../../../.claude/skills/) 에 있다.

**먼저 읽을 것은 `kotlin-common` 하나다.** 나머지 10종은 지금 고치는 파일이 어느 계층인지에 따라 골라 읽는다.

| 스킬 | 언제 읽나 | 다루는 것 |
|---|---|---|
| [kotlin-common](kotlin-common/SKILL.md) | **모든 백엔드 작업** | 2대 원칙, 자료형, 불변성, 조건문 풀어쓰기, 이름, 예외, 주석, 검증 |
| [kotlin-module-layout](kotlin-module-layout/SKILL.md) | 새 파일을 어디 둘지 모를 때 | 모듈 배치표, 의존 방향, 도메인 경계 |
| [kotlin-controller](kotlin-controller/SKILL.md) | 엔드포인트 추가·변경 | `@RestController`, 요청/응답 변환, `ApiResponse` 래핑 |
| [kotlin-dto](kotlin-dto/SKILL.md) | 요청·응답 형태 변경 | 검증 애너테이션, 도메인 모델과의 변환 |
| [kotlin-domain-service](kotlin-domain-service/SKILL.md) | 업무 흐름·트랜잭션 | 유스케이스 조립, `@Transactional` 경계 |
| [kotlin-implement](kotlin-implement/SKILL.md) | 조회·저장 상세 구현 | `Finder`·`Appender` 재사용 단위, 엔티티↔도메인 변환 |
| [kotlin-entity](kotlin-entity/SKILL.md) | 테이블·상태 변경 | `@Entity`, `protected set` + 행위 메서드, 애그리게이트 |
| [kotlin-repository](kotlin-repository/SKILL.md) | 쿼리 추가, 느린 쿼리 | 쿼리 메서드 이름, 페이징, fetch join 과 N+1 |
| [kotlin-migration](kotlin-migration/SKILL.md) | **엔티티를 바꿀 때마다 함께** | Flyway 파일 이름·자리, 적용된 파일 불변, 무중단 배포 순서 |
| [kotlin-error](kotlin-error/SKILL.md) | 실패 분기를 만들 때 | `ErrorCode`·`ErrorType`·`CoreException`, 상태코드·로그 레벨 |
| [kotlin-test](kotlin-test/SKILL.md) | **기능 작업마다 함께** | 한 메서드 = 한 기능, MockK 범위, 계층별 테스트 대상 |

## 만드는 순서

새 도메인 하나를 추가할 때는 위에서 아래로 만든다. 아래에서 위로 쌓아야 상위 계층이 이미 있는 것을 조립하게 된다.

    enum → 엔티티 + 마이그레이션 → 리포지토리 → 도메인 모델 → 구현 레이어 → 도메인 서비스 → DTO → 컨트롤러

배치표(어느 모듈의 어느 패키지에 두는지)는 `kotlin-module-layout` 에 있다.

## 문서 구조

스킬 11종 모두 같은 모양이다. 마지막 두 절만 봐도 리뷰는 된다.

- **규칙** — 지켜야 할 것

- **적발 신호** — 리뷰에서 잡아낼 패턴. `Critical` 은 머지 차단 사유이고, `Important` 는 참고 코멘트로만 남는다

- **체크리스트** — 작업을 끝내기 전 확인할 것

머지를 막는 기준 전체는 [common/docs/code-review/rules.md](../../../common/docs/code-review/rules.md) 에 있다.
