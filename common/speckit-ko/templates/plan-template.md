# 구현 계획: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [링크]

**Input**: `/specs/[###-feature-name]/spec.md` 의 기능 명세

**Note**: 이 템플릿은 `__SPECKIT_COMMAND_PLAN__` 명령이 채운다. 실행 절차는 그 명령 정의에 적혀 있다.

## Summary (요약)

[기능 명세에서 뽑은 핵심 요구사항 + 조사로 정한 기술적 접근]

## Technical Context (기술 맥락)

<!--
  해야 할 일: 아래를 이 기능의 실제 값으로 바꾼다.
  정해지지 않은 항목은 NEEDS CLARIFICATION 으로 남긴다 — 빈칸으로 두지 않는다.
-->

**Language/Version**: [예: Kotlin 1.9 + Spring Boot 3.x, TypeScript + React Native(Expo) 또는 NEEDS CLARIFICATION]

**Primary Dependencies**: [예: Spring Data JPA, Flyway, MockK, Expo Router 또는 NEEDS CLARIFICATION]

**Storage**: [해당하면 적는다. 예: MySQL + Flyway 마이그레이션, 없으면 N/A]

**Testing**: [예: JUnit5 + MockK + AssertJ(`./gradlew unitTest`), Playwright(E2E) 또는 NEEDS CLARIFICATION]

**Target Platform**: [예: 리눅스 서버, iOS/Android/웹 또는 NEEDS CLARIFICATION]

**Project Type**: [예: 백엔드 API, 프론트 화면, 백엔드+프론트 동시 또는 NEEDS CLARIFICATION]

**Performance Goals**: [해당 영역 기준. 예: 초당 요청 수, 응답 시간 또는 NEEDS CLARIFICATION]

**Constraints**: [해당 영역 기준. 예: p95 200ms 미만, 오프라인 동작 또는 NEEDS CLARIFICATION]

**Scale/Scope**: [해당 영역 기준. 예: 사용자 1만, 화면 20개 또는 NEEDS CLARIFICATION]

## Constitution Check (헌법 점검)

*관문: Phase 0 조사 전에 통과해야 한다. Phase 1 설계 후에 다시 확인한다.*

[`constitution.md` 가 가리키는 규칙으로 판정한다. 이 저장소에서 머지를 막는 기준은 `common/docs/code-review/rules.md` 와 각 스킬의 '적발 신호' 중 Critical 항목이다]

## Project Structure (프로젝트 구조)

### Documentation (이 기능의 문서)

```text
specs/[###-feature]/
├── plan.md              # 이 파일 (__SPECKIT_COMMAND_PLAN__ 출력)
├── research.md          # Phase 0 출력 (__SPECKIT_COMMAND_PLAN__)
├── data-model.md        # Phase 1 출력 (__SPECKIT_COMMAND_PLAN__)
├── quickstart.md        # Phase 1 출력 (__SPECKIT_COMMAND_PLAN__)
├── contracts/           # Phase 1 출력 (__SPECKIT_COMMAND_PLAN__)
└── tasks.md             # Phase 2 출력 (__SPECKIT_COMMAND_TASKS__ — __SPECKIT_COMMAND_PLAN__ 이 만들지 않는다)
```

### Source Code (저장소 루트)

<!--
  해야 할 일: 아래 뼈대에서 이 기능이 실제로 건드리는 경로만 남기고 구체적으로 적는다.
  파일을 어느 모듈·패키지에 둘지는 backend/.claude/skills/kotlin-module-layout 이 정한다.
-->

```text
# 백엔드 — Kotlin + Spring Boot 멀티모듈 (레이어 방향: controller → domain service → implement → repository)
backend/
├── core/
│   ├── core-<도메인>/           # 컨트롤러·DTO·도메인 서비스·구현 레이어(Finder·Appender 등)
│   ├── core-common/             # 여러 도메인이 함께 쓰는 것 (응답 래퍼, 이벤트 타입)
│   └── core-enum/               # 여러 모듈이 공유하는 enum
├── storage/db-core/             # @Entity, JpaRepository, Flyway 마이그레이션
├── clients/client-<이름>/       # 외부 시스템 통신은 예외 없이 여기
└── support/                     # 상위(core)를 참조하지 않는 보조 기능

# 프론트엔드 — 도메인이 최상위 폴더 (레이어 방향: screens → hooks → services → api → lib)
frontend/src/
├── <도메인>/
│   ├── screens/ components/ hooks/ services/ api/
│   └── enums/ types/
└── common/                      # 여러 도메인이 함께 쓰는 것
```

**Structure Decision**: [위에서 고른 구조와 실제 경로를 적는다. 새 도메인을 만든다면 왜 기존 도메인에 속하지 않는지 함께 적는다]

## Complexity Tracking (복잡도 근거)

> **헌법 점검에서 위반이 나왔고 그것을 정당화해야 할 때만 채운다**

| 위반 | 왜 필요한가 | 더 단순한 방법을 버린 이유 |
|-----------|------------|-------------------------------------|
| [예: 새 도메인 모듈 추가] | [지금 필요한 것] | [기존 도메인으로 안 되는 이유] |
| [예: 트랜잭션 안 외부 호출] | [구체적 문제] | [이벤트 분리로 안 되는 이유] |
