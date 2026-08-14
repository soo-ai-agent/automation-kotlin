---
name: kotlin-module-layout
description: 멀티모듈 배치와 레이어 의존 방향 규칙. 새 파일을 어느 모듈·패키지에 둘지, 어떤 레이어가 무엇을 참조할 수 있는지 정한다. 새 기능이나 도메인을 추가할 때, "이 클래스를 어디에 두나"를 판단할 때, 레이어 위반을 리뷰할 때 사용한다.
---

# 모듈 배치와 의존 방향

## 모듈

| 모듈 | 담는 것 |
|---|---|
| `core:core-api` | 컨트롤러, 도메인 서비스, 구현 레이어, 지원 코드(error/response) |
| `core:core-enum` | 도메인 enum |
| `storage:db-core` | JPA 엔티티, 리포지토리, DB 설정 |
| `clients:client-*` | 외부 시스템 호출 어댑터 |
| `support:logging` `support:monitoring` | 횡단 관심사 |
| `tests:api-docs` | API 문서 테스트 |

## 템플릿과 다른 점 — 여기가 성장형이다

Spring 템플릿(`team-dodn/spring-boot-kotlin-template`)이 동봉한 `ExampleService.kt` 는 `core/domain/` 평면에 있고 구현 레이어도 없다. **그것을 따라 하지 않는다.**

템플릿 README 가 직접 밝히고 있다 — "This is not the best structure... **your structure must grow too**". 도메인 서브패키지와 구현 레이어가 그 성장형이고, 이 문서의 배치표가 이 저장소의 기준이다.

동봉된 `Example*` 파일은 첫 도메인을 만든 뒤 지운다. 그때까지는 평면에 있어도 지적하지 않는다.

## 새 도메인 하나를 추가할 때의 파일 자리

```
core/core-enum/.../core/enums/TodoStatus.kt                     enum
storage/db-core/.../storage/db/core/TodoEntity.kt               엔티티
storage/db-core/.../storage/db/core/TodoRepository.kt           리포지토리
core/core-api/.../core/domain/todo/Todo.kt                      도메인 모델
core/core-api/.../core/domain/todo/implement/TodoFinder.kt      구현 레이어
core/core-api/.../core/domain/todo/implement/TodoAppender.kt
core/core-api/.../core/domain/todo/TodoService.kt               도메인 서비스
core/core-api/.../core/api/controller/v1/request/TodoCreateRequestDto.kt
core/core-api/.../core/api/controller/v1/response/TodoResponseDto.kt
core/core-api/.../core/api/controller/v1/TodoController.kt      컨트롤러
```

**만드는 순서는 위에서 아래로.** 아래에서 위로 쌓아야 상위 레이어가 이미 있는 것을 조립하게 된다.

## 의존 방향 — 상위에서 하위로만

```
Controller  →  Domain Service  →  Implement  →  Repository / Client
                     ↓
                Domain Model
```

- 역방향 참조 금지. 하위 레이어가 상위를 알면 안 된다.

- 레이어 건너뛰기 금지: 컨트롤러가 리포지토리를, 도메인 서비스가 리포지토리를 직접 부르지 않는다.

- **엔티티는 `storage` 밖으로 나가지 않는다.** 구현 레이어가 엔티티를 도메인 모델로 바꿔 위로 올린다.

- 컨트롤러의 요청/응답 DTO 는 도메인 아래로 내려가지 않는다.

- 도메인 모델은 JPA·Spring Web 애너테이션을 갖지 않는다. 프레임워크 의존은 엔티티·컨트롤러·어댑터에만 둔다.

## 도메인 경계

- 다른 도메인의 구현 레이어·리포지토리를 직접 부르지 않는다. 필요하면 그 도메인의 **서비스**를 통한다.

- 애그리게이트 경계를 넘는 상태 변경은 루트 엔티티를 통해 수행한다 (kotlin-entity 참고).

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 컨트롤러가 리포지토리·엔티티를 직접 참조 | 레이어 건너뛰기 | Critical |
| 엔티티가 `core-api` 에 노출됨(반환·파라미터) | 저장소 격리 붕괴 | Critical |
| 도메인 서비스가 리포지토리를 직접 호출 | 구현 레이어 우회 | Critical |
| 하위 레이어가 상위 타입을 import | 역방향 의존 | Critical |
| 다른 도메인의 구현 레이어 직접 호출 | 도메인 경계 침범 | Critical |
| 도메인 모델에 JPA·Web 애너테이션 | 프레임워크 침투 | Important |
| 도메인 디렉터리 없이 `core/domain` 평면에 파일 누적 (템플릿 동봉 `Example*` 은 제외) | 경계 흐려짐 | Important |

## 체크리스트

- [ ] 새 파일이 위 배치표의 자리에 있는가

- [ ] import 방향이 상위 → 하위 단방향인가

- [ ] 엔티티가 `storage` 모듈 밖으로 새지 않았는가

- [ ] 다른 도메인은 서비스를 통해서만 참조하는가
