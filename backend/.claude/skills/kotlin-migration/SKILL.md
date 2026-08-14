---
name: kotlin-migration
description: DB 스키마 변경 규칙. Flyway 마이그레이션 파일의 자리와 이름, 프로파일별 동작, 이미 적용된 파일을 고치지 않는 규칙, 무중단 배포를 위한 컬럼 추가·삭제 순서를 다룬다. 엔티티에 필드나 테이블을 추가·변경·삭제할 때 kotlin-entity 와 항상 함께 사용한다. "테이블 추가", "컬럼 추가", "스키마 변경", "마이그레이션" 요청에도 사용할 것.
---

# DB 마이그레이션 (Flyway)

**자리:** `storage/db-core/src/main/resources/db/migration/V<버전>__<설명>.sql`

## 왜 필요한가 — 엔티티만 바꾸면 배포가 깨진다

이 프로젝트는 운영 환경에서 `ddl-auto: validate` 로 돈다. Hibernate 가 시작할 때 **엔티티와 실제 테이블이 다르면 애플리케이션이 아예 뜨지 않는다.**

즉 엔티티에 필드를 하나 추가하고 배포하면, 그 컬럼을 만드는 SQL 이 없는 한 부팅에 실패한다.

그 SQL 을 담는 곳이 마이그레이션 파일이고, Flyway 가 배포 때 순서대로 실행한다.

| 프로파일 | DB | `ddl-auto` | Flyway | 스키마의 원본 |
|---|---|---|---|---|
| `local` | H2 (메모리) | `create` | 꺼짐 | 엔티티 — 뜰 때마다 새로 만든다 |
| `local-dev` · `dev` · `staging` · `live` | MySQL | `validate` | 켜짐 | **마이그레이션 파일** |

`local` 만 예외인 이유는 네트워크 없이 개발하려고 메모리 DB 를 쓰기 때문이다. 나머지는 전부 마이그레이션이 기준이다.

## 파일 이름 — 버전은 날짜와 시각으로

```
V202608141530__add_todo_due_date.sql
│└──────────┘  └────────────────┘
│  버전(분까지)     무엇을 하는지 (소문자 스네이크)
└ 접두 V 는 고정
```

- 버전은 **`YYYYMMDDHHmm`** 로 쓴다. 순번(`V1`, `V2`)을 쓰지 않는다.

  이 저장소는 `claude-split` 으로 하위 이슈를 **병렬로** 진행한다. 두 작업이 동시에 `V3` 을 만들면 Flyway 가 중복 버전으로 실패한다. 시각 기반이면 부딪히지 않는다.

- 설명은 파일만 보고 무엇을 하는지 알 수 있게 쓴다. `V202608141530__update.sql` 은 이름이 없는 것과 같다.

- 구분자는 **밑줄 두 개**(`__`)다. 하나면 Flyway 가 인식하지 못한다.

## 쓰는 법

```sql
-- V202608141530__add_todo_due_date.sql
ALTER TABLE todo
    ADD COLUMN due_date DATE NULL COMMENT '마감일';
```

- **엔티티 변경과 마이그레이션은 같은 커밋에 넣는다.** 따로 커밋하면 그 사이 커밋에서 빌드가 깨진다.

- 테이블을 새로 만들 때는 `BaseEntity` 가 갖는 세 컬럼(`id`, `created_at`, `updated_at`)을 빠뜨리지 않는다.

```sql
-- V202608141600__create_todo.sql
CREATE TABLE todo (
    id         BIGINT       NOT NULL AUTO_INCREMENT,
    member_id  BIGINT       NOT NULL,
    title      VARCHAR(200) NOT NULL,
    done       TINYINT(1)   NOT NULL DEFAULT 0,
    created_at DATETIME     NOT NULL,
    updated_at DATETIME     NOT NULL,
    PRIMARY KEY (id),
    KEY idx_todo_member_id (member_id)
);
```

- 조회 조건으로 쓰는 컬럼에는 인덱스를 같이 만든다. 엔티티의 `@Table(indexes = [...])` 와 이름을 맞춘다.

## 절대 하면 안 되는 것 — 적용된 파일 수정

**한 번이라도 실행된 마이그레이션 파일은 고치지도, 지우지도, 이름을 바꾸지도 않는다.**

Flyway 는 실행한 파일의 체크섬을 DB 에 기록해 둔다. 내용이 바뀌면 다음 배포에서 체크섬 불일치로 **멈춘다.**

잘못 만들었으면 그 파일을 고치는 대신 **바로잡는 새 파일을 추가한다.**

아직 아무 데도 배포되지 않았다고 확신할 수 있을 때만(= 내 브랜치에서 방금 만들었고 아직 머지 전) 고쳐도 된다.

## 배포 중에도 앱은 돌고 있다 — 확장 후 수축

배포는 순간이 아니다. 새 버전이 뜨는 동안 **구버전 앱이 같은 DB 를 보고 돌아간다.** 그래서 순서가 중요하다.

**컬럼 추가** — 한 번에 해도 안전하다. 단, `NULL` 허용이거나 `DEFAULT` 가 있어야 한다.

```sql
ALTER TABLE todo ADD COLUMN due_date DATE NULL;
```

`NOT NULL` 을 기본값 없이 추가하면 구버전 앱의 INSERT 가 전부 실패한다.

**컬럼 삭제·이름 변경** — 반드시 **배포 두 번**에 나눠서 한다.

| 순서 | 배포 | 하는 일 |
|---|---|---|
| 1 | 앱 먼저 | 코드에서 그 컬럼을 더 이상 읽지도 쓰지도 않게 바꾼다. 스키마는 그대로 |
| 2 | 그다음 | 아무도 안 쓰는 것을 확인하고 `DROP COLUMN` 마이그레이션을 넣는다 |

이름 변경은 삭제와 같다 — `RENAME` 대신 **새 컬럼 추가 → 데이터 복사 → 구 컬럼 삭제** 세 단계로 나눈다.

**데이터를 옮기는 SQL 과 스키마를 바꾸는 SQL 은 파일을 나눈다.** 하나가 실패했을 때 어디까지 됐는지 알 수 있어야 한다.

## 처음 한 번 — 의존성과 설정

사람이 뼈대를 만들 때 넣는다 (`backend/README.md` 참고). 이미 되어 있으면 넘어간다.

```kotlin
// storage/db-core/build.gradle.kts
implementation("org.flywaydb:flyway-core")
runtimeOnly("org.flywaydb:flyway-mysql")
```

```yaml
# storage/db-core/src/main/resources/db-core.yml 의 local 프로파일
spring:
  flyway:
    enabled: false   # local 은 H2 + ddl-auto: create 라 마이그레이션을 돌리지 않는다
```

버전은 적지 않는다 — Spring Boot 의 의존성 관리가 맞는 버전을 넣어 준다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 엔티티·컬럼이 바뀌었는데 마이그레이션 파일이 없음 | 운영에서 `validate` 실패로 부팅 불가 | Critical |
| 이미 머지된 마이그레이션 파일을 수정·삭제·개명 | 체크섬 불일치로 이후 배포 전부 중단 | Critical |
| 기본값 없는 `NOT NULL` 컬럼 추가 | 배포 중 구버전 앱의 INSERT 실패 | Critical |
| 한 배포에서 컬럼을 지우거나 이름 변경 | 배포 중 구버전 앱이 없는 컬럼 참조 | Critical |
| 순번 버전(`V1`, `V2`) 사용 | 병렬 하위 이슈끼리 버전 충돌 | Important |
| 구분자가 밑줄 하나(`V..._name.sql`) | Flyway 가 파일을 인식하지 못함 | Important |
| 엔티티 변경과 마이그레이션이 다른 커밋 | 중간 커밋에서 빌드·부팅 깨짐 | Important |
| 스키마 변경과 데이터 이관이 한 파일 | 실패 지점 파악 불가 | Important |
| 새 테이블에 `created_at`·`updated_at` 누락 | `BaseEntity` 와 불일치 | Important |

## 체크리스트

- [ ] 엔티티를 바꿨다면 같은 커밋에 마이그레이션 파일이 있는가

- [ ] 파일명이 `V<YYYYMMDDHHmm>__<설명>.sql` 이고 밑줄이 두 개인가

- [ ] 추가한 컬럼이 `NULL` 허용이거나 `DEFAULT` 를 갖는가

- [ ] 삭제·개명을 한 배포에 몰아넣지 않았는가

- [ ] 이미 머지된 마이그레이션 파일을 건드리지 않았는가

- [ ] 새 테이블에 `id`·`created_at`·`updated_at` 과 필요한 인덱스가 있는가
