---
name: kotlin-module-layout
description: 멀티모듈 배치와 레이어 의존 방향 규칙. 새 파일을 어느 모듈·패키지에 둘지, 어떤 레이어가 무엇을 참조할 수 있는지 정한다. 새 기능이나 도메인을 추가할 때, "이 클래스를 어디에 두나"를 판단할 때, 레이어 위반을 리뷰할 때 사용한다.
---

# 모듈 배치와 의존 방향

## 왜 한 덩어리로 안 만드나

이 프로젝트는 폴더가 아니라 **Gradle 모듈**로 나뉘어 있다. 모듈은 폴더와 달리 **서로 참조할 수 있는 방향이 빌드 설정으로 강제된다.**

`storage:db-core` 는 `core:core-<도메인>` 를 참조할 수 없다. 실수로 참조하면 컴파일이 안 된다. 규칙을 사람이 기억하는 대신 빌드가 지켜 주는 것이다.

## 엔티티와 도메인 모델이 둘인 이유

같은 "할 일" 하나를 두 가지 타입으로 표현한다. 헷갈리기 쉬우니 먼저 구분한다.

| | 무엇인가 | 어디 사나 |
|---|---|---|
| `TodoEntity` | **DB 테이블의 한 행.** JPA 애너테이션이 붙어 있고 영속성 문맥에 묶여 있다 | `storage` 모듈 안에서만 |
| `Todo` | **업무 개념.** 프레임워크를 모르는 순수한 데이터 | `core:core-todo` 의 도메인·서비스·컨트롤러 |

나누는 이유는 **DB 사정이 업무 코드로 번지지 않게** 하기 위해서다. 컬럼을 쪼개거나 테이블을 합쳐도 도메인 모델이 그대로면 위쪽 코드는 아무것도 모른다.

둘 사이의 변환은 **구현 레이어 한 곳에서만** 한다 (`kotlin-implement`).

## 모듈

| 모듈 | 담는 것 | 담지 않는 것 |
|---|---|---|
| `api` | **유일한 부팅 모듈.** 부팅 클래스, ControllerAdvice, 헬스, 전역 설정 | 특정 도메인의 Controller·Service |
| `core:core-<도메인>` | 한 도메인을 통째로 — 그 도메인의 Controller·DTO·Service·구현체·도메인 모델 | 다른 도메인의 코드, 저장 구현, 외부 호출 |
| `core:core-common` | **둘 이상의 도메인이** 쓰는 것만 — 예외 베이스, 공용 요청 DTO | 한 도메인만 쓰는 것 |
| `core:core-enum` | **여러 모듈이** 공유하는 enum | 한 모듈만 쓰는 enum, 값·로직 |
| `storage:db-core` | 저장·조회. 엔티티·리포지토리·저장 모델 | 비즈니스 흐름, HTTP |
| `clients:client-*` | 외부 시스템 호출 어댑터 | 비즈니스 판단, 저장소 접근 |
| `support:*` | 로깅·모니터링·도메인 지식 없는 범용 함수 | 도메인 코드 일체 |

### 도메인 모듈 안은 두 겹이다

```
core/core-<도메인>/…/core/<도메인>/
  api/     controller/ · request/ · response/
  domain/  service/ · model/ · error/ · (config/)
```

`api` → `domain` 한 방향이다. `domain` 이 `api` 의 DTO 를 알면 위반이다.
응답 DTO 로의 변환은 **Controller 가** 하고, 변환 함수는 그 DTO 의 `companion` 이 갖는다.

### 모듈로 나눌지, 패키지로 둘지

역참조가 0인 것만으로는 부족하다. **바깥(부팅 모듈·다른 도메인)이 그 모듈을 import 하는지 센다.**

| 재는 것 | 나눌 값이 있는 신호 |
|---|---|
| 역참조 수 | 0 (필요조건일 뿐) |
| **바깥의 import 수** | **1 이상.** 0이면 패키지로 충분하다 |

Spring 은 컴포넌트 스캔으로 빈을 찾으므로, 도메인 안쪽 협력자를 모듈로 떼어도
바깥은 그 이름을 부를 일이 없다. 그러면 경계가 파는 것은 내부 방향 강제뿐이고,
그건 의존 방향 테스트로 더 싸게 산다. 모듈을 접으면 그 자리에 방향 테스트를 남긴다.

## 템플릿과 다른 점 — 여기가 성장형이다

Spring 템플릿(`team-dodn/spring-boot-kotlin-template`)이 동봉한 `ExampleService.kt` 는 `core/domain/` 평면에 있고 구현 레이어도 없다. **그것을 따라 하지 않는다.**

템플릿 README 가 직접 밝히고 있다 — "This is not the best structure... **your structure must grow too**". 도메인 서브패키지와 구현 레이어가 그 성장형이고, 이 문서의 배치표가 이 저장소의 기준이다.

동봉된 `Example*` 파일은 첫 도메인을 만든 뒤 지운다. 그때까지는 평면에 있어도 지적하지 않는다.

## 새 도메인 하나를 추가할 때의 파일 자리

```
core/core-enum/.../core/enums/TodoStatus.kt                     enum
storage/db-core/.../storage/db/core/TodoEntity.kt               엔티티
storage/db-core/.../storage/db/core/TodoRepository.kt           리포지토리
core/core-<도메인>/.../<도메인>/domain/model/Todo.kt                      도메인 모델
core/core-<도메인>/.../<도메인>/domain/service/TodoFinder.kt      구현 레이어
core/core-<도메인>/.../<도메인>/domain/service/TodoAppender.kt
core/core-<도메인>/.../<도메인>/domain/service/TodoService.kt               도메인 서비스
core/core-<도메인>/.../<도메인>/api/request/TodoCreateRequestDto.kt
core/core-<도메인>/.../<도메인>/api/response/TodoResponseDto.kt
core/core-<도메인>/.../<도메인>/api/controller/TodoController.kt      컨트롤러
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
| 엔티티가 도메인 모듈에 노출됨(반환·파라미터) | 저장소 격리 붕괴 | Critical |
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
