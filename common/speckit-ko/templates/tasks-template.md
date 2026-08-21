---

description: "기능 구현용 작업 목록 템플릿"
---

# 작업 목록: [FEATURE NAME]

**Input**: `/specs/[###-feature-name]/` 의 설계 문서

**Prerequisites**: plan.md (필수), spec.md (사용자 스토리에 필요), research.md, data-model.md, contracts/

**Tests**: **이 저장소에서 테스트는 선택이 아니다.** 새 동작(분기·정책·검증·상태 변경)에는 같은 변경에 유닛 테스트가 포함된다 — `common/docs/code-review/rules.md` 의 MUST 항목이라 빠지면 머지가 막힌다.

**Organization**: 작업은 사용자 스토리별로 묶는다. 그래야 스토리 하나를 따로 구현하고 따로 검증할 수 있다.

## 형식: `[ID] [P?] [Story] 설명`

- **[P]**: 병렬 실행 가능 (건드리는 파일이 다르고 서로 의존하지 않음)
- **[Story]**: 이 작업이 속한 사용자 스토리 (예: US1, US2, US3)
- 설명에 **정확한 파일 경로**를 적는다

## 경로 규약

- **백엔드**: `backend/core/core-<도메인>/`, `backend/storage/db-core/`, `backend/clients/client-<이름>/`
- **프론트엔드**: `frontend/src/<도메인>/<계층>/`, 공용은 `frontend/src/common/`
- 파일을 어느 모듈에 둘지는 `backend/.claude/skills/kotlin-module-layout` 이 정한다

<!--
  ============================================================================
  중요: 아래 작업들은 형식을 보여주는 **예시**다.

  __SPECKIT_COMMAND_TASKS__ 명령은 이것들을 실제 작업으로 바꿔야 한다. 근거는 넷이다.
  - spec.md 의 사용자 스토리 (우선순위 P1, P2, P3 ...)
  - plan.md 의 요구사항
  - data-model.md 의 데이터
  - contracts/ 의 엔드포인트

  작업은 반드시 사용자 스토리별로 묶는다. 그래야 스토리마다
  따로 구현하고, 따로 검증하고, MVP 한 조각으로 낼 수 있다.

  생성된 tasks.md 에 이 예시를 남겨 두지 않는다.
  ============================================================================
-->

## Phase 1: Setup (공통 준비)

**목적**: 프로젝트 초기화와 기본 구조

- [ ] T001 구현 계획대로 모듈·패키지 자리 만들기
- [ ] T002 [언어] 프로젝트에 [프레임워크] 의존성 추가
- [ ] T003 [P] 린트·포맷 도구 설정 (`ktlintCheck` 등)

---

## Phase 2: Foundational (막고 있는 선행 작업)

**목적**: 어떤 사용자 스토리든 시작하기 전에 반드시 끝나 있어야 하는 기반

**⚠️ 중요**: 이 단계가 끝나기 전에는 스토리 작업을 시작할 수 없다

기반 작업의 예 (프로젝트에 맞게 조정한다):

- [ ] T004 엔티티와 Flyway 마이그레이션 (**엔티티를 바꾸면 같은 변경에 마이그레이션이 들어간다**)
- [ ] T005 [P] 인증·권한 기반 만들기
- [ ] T006 [P] 공통 응답 래퍼·예외 처리 구조 확인
- [ ] T007 모든 스토리가 쓰는 기본 도메인 모델 만들기
- [ ] T008 로그 남길 자리 정하기
- [ ] T009 설정값·비밀값 주입 자리 만들기

**체크포인트**: 기반 완료 — 이제 사용자 스토리를 병렬로 시작할 수 있다

---

## Phase 3: User Story 1 - [제목] (Priority: P1) 🎯 MVP

**목표**: [이 스토리가 무엇을 주는지 한 줄]

**혼자 검증하는 법**: [이것만으로 동작을 어떻게 확인하는지]

### Tests for User Story 1 (US1 테스트)

> **먼저 쓴다.** 구현 전에 실패하는 것을 확인하고 시작한다.

- [ ] T010 [P] [US1] [대상] 유닛 테스트 — `backend/core/core-<도메인>/src/test/kotlin/.../XxxTest.kt`
- [ ] T011 [P] [US1] [사용자 여정] 검증 테스트

### Implementation for User Story 1 (US1 구현)

아래는 이 저장소의 레이어 순서다 — 아래에서 위로 쌓아야 상위가 이미 있는 것을 조립한다.

- [ ] T012 [P] [US1] enum 선언 — 여럿이 쓰면 `core-enum`, 한 모듈만 쓰면 그 모듈
- [ ] T013 [P] [US1] `[대상]Entity` 와 Flyway 마이그레이션 — `backend/storage/db-core/`
- [ ] T014 [US1] `[대상]Repository` 조회 메서드 추가 (T013 에 의존)
- [ ] T015 [US1] 도메인 모델(`[대상]Result`) 과 구현 레이어(`[대상]Finder`·`[대상]Appender`)
- [ ] T016 [US1] 도메인 서비스에 흐름 조립 + `@Transactional` 경계
- [ ] T017 [US1] 요청·응답 DTO 와 검증 애너테이션(`@Valid`, `@field:`)
- [ ] T018 [US1] 컨트롤러 엔드포인트 추가

**체크포인트**: 여기까지 하면 User Story 1 이 혼자 동작하고 혼자 검증된다

---

## Phase 4: User Story 2 - [제목] (Priority: P2)

**목표**: [이 스토리가 무엇을 주는지 한 줄]

**혼자 검증하는 법**: [이것만으로 동작을 어떻게 확인하는지]

### Tests for User Story 2 (US2 테스트)

- [ ] T019 [P] [US2] [대상] 유닛 테스트
- [ ] T020 [P] [US2] [사용자 여정] 검증 테스트

### Implementation for User Story 2 (US2 구현)

- [ ] T021 [P] [US2] 엔티티·마이그레이션 (필요하면)
- [ ] T022 [US2] 구현 레이어와 도메인 서비스
- [ ] T023 [US2] DTO 와 컨트롤러
- [ ] T024 [US2] User Story 1 과 이어 붙이기 (필요하면)

**체크포인트**: User Story 1 과 2 가 각각 혼자 동작한다

---

## Phase 5: User Story 3 - [제목] (Priority: P3)

**목표**: [이 스토리가 무엇을 주는지 한 줄]

**혼자 검증하는 법**: [이것만으로 동작을 어떻게 확인하는지]

### Tests for User Story 3 (US3 테스트)

- [ ] T025 [P] [US3] [대상] 유닛 테스트
- [ ] T026 [P] [US3] [사용자 여정] 검증 테스트

### Implementation for User Story 3 (US3 구현)

- [ ] T027 [P] [US3] 엔티티·마이그레이션 (필요하면)
- [ ] T028 [US3] 구현 레이어와 도메인 서비스
- [ ] T029 [US3] DTO 와 컨트롤러

**체크포인트**: 모든 사용자 스토리가 각각 혼자 동작한다

---

[필요한 만큼 스토리 단계를 더 쓴다. 형식은 위와 같다]

---

## Phase N: Polish & Cross-Cutting (마무리와 공통 사항)

**목적**: 여러 스토리에 걸치는 개선

- [ ] TXXX [P] 문서 갱신 — `CONTRACT.md`, `docs/`, 바뀐 규칙을 말하는 md 전부
- [ ] TXXX 코드 정리 (동작 변경과 같은 커밋에 섞지 않는다)
- [ ] TXXX 성능 개선
- [ ] TXXX [P] 빠진 유닛 테스트 보강
- [ ] TXXX 보안 점검 — 소유자 스코프, 비밀값 노출
- [ ] TXXX `./gradlew ktlintCheck unitTest` 통과 확인과 **테스트 실계수 보고**

---

## Dependencies & Execution Order (의존과 실행 순서)

### 단계 의존

- **Setup (Phase 1)**: 의존 없음 — 바로 시작
- **Foundational (Phase 2)**: Setup 완료에 의존 — **모든 사용자 스토리를 막는다**
- **User Stories (Phase 3+)**: 전부 Foundational 완료에 의존
  - 이후 스토리끼리는 병렬 진행 가능 (사람이 있으면)
  - 아니면 우선순위 순서대로 (P1 → P2 → P3)
- **Polish (마지막 단계)**: 원하는 스토리가 모두 끝난 뒤

### 사용자 스토리 사이

- **User Story 1 (P1)**: Foundational 후 시작 가능 — 다른 스토리에 의존하지 않는다
- **User Story 2 (P2)**: Foundational 후 시작 가능 — US1 과 이어 붙을 수 있지만 혼자 검증돼야 한다
- **User Story 3 (P3)**: Foundational 후 시작 가능 — US1·US2 와 이어 붙을 수 있지만 혼자 검증돼야 한다

### 스토리 하나 안에서

- 테스트를 먼저 쓰고, 구현 전에 실패하는 것을 확인한다
- 엔티티·마이그레이션 → 리포지토리 → 도메인 모델 → 구현 레이어 → 도메인 서비스 → DTO → 컨트롤러
- 핵심 구현이 끝난 뒤에 다른 스토리와 이어 붙인다
- 스토리 하나를 끝내고 다음 우선순위로 넘어간다

### 병렬 가능한 것

- `[P]` 가 붙은 Setup 작업들
- `[P]` 가 붙은 Foundational 작업들 (Phase 2 안에서)
- Foundational 이 끝나면 모든 사용자 스토리 (인원이 되면)
- 한 스토리 안에서 `[P]` 가 붙은 테스트들
- 한 스토리 안에서 `[P]` 가 붙은 엔티티들

---

## 병렬 실행 예: User Story 1

```bash
# US1 테스트를 한꺼번에 시작
Task: "[대상] 유닛 테스트 — backend/core/core-<도메인>/src/test/kotlin/.../XxxTest.kt"
Task: "[사용자 여정] 검증 테스트"

# US1 엔티티를 한꺼번에 시작
Task: "[대상1]Entity 만들기 — backend/storage/db-core/.../[대상1]Entity.kt"
Task: "[대상2]Entity 만들기 — backend/storage/db-core/.../[대상2]Entity.kt"
```

---

## 구현 전략

### MVP 먼저 (User Story 1 만)

1. Phase 1 Setup 완료
2. Phase 2 Foundational 완료 (**모든 스토리를 막는 단계**)
3. Phase 3 User Story 1 완료
4. **멈추고 확인**: User Story 1 을 혼자 검증한다
5. 괜찮으면 배포·시연

### 조금씩 늘리기

1. Setup + Foundational 완료 → 기반 준비
2. User Story 1 추가 → 혼자 검증 → 배포·시연 (MVP)
3. User Story 2 추가 → 혼자 검증 → 배포·시연
4. User Story 3 추가 → 혼자 검증 → 배포·시연
5. 스토리를 더해도 앞의 스토리가 깨지지 않는다

### 여럿이 나눠서

1. Setup + Foundational 을 다 같이 끝낸다
2. 끝나면 나눠 맡는다
   - 개발자 A: User Story 1
   - 개발자 B: User Story 2
   - 개발자 C: User Story 3
3. 각 스토리가 따로 끝나고 따로 합쳐진다

---

## Notes (메모)

- `[P]` 는 건드리는 파일이 다르고 서로 의존하지 않는다는 뜻이다
- `[Story]` 표시는 작업이 어느 스토리 것인지 되짚기 위한 것이다
- 스토리 하나하나가 혼자 끝나고 혼자 검증돼야 한다
- 구현 전에 테스트가 실패하는 것을 확인한다
- 작업 하나 또는 한 묶음마다 커밋한다 — 리팩터링과 동작 변경을 같은 커밋에 섞지 않는다
- 어느 체크포인트에서든 멈춰서 그 스토리만 검증할 수 있다
- 피할 것: 뭉뚱그린 작업, 같은 파일을 동시에 고치는 병렬 작업, 스토리 독립성을 깨는 교차 의존
