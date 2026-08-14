# backend

Kotlin + Spring Boot 멀티모듈 앱이다. **모든 명령은 이 폴더 안에서 실행한다.** JDK 21 을 쓴다.

이 저장소는 에이전트 배선과 규칙만 담고 있다. 실제 Spring 모듈은 아래처럼 채운다.

## 1. 뼈대 가져오기

[team-dodn/spring-boot-kotlin-template](https://github.com/team-dodn/spring-boot-kotlin-template)
에서 가져온다.

```bash
cd backend
git clone --depth 1 https://github.com/team-dodn/spring-boot-kotlin-template.git /tmp/tpl
cp -r /tmp/tpl/core /tmp/tpl/storage /tmp/tpl/support /tmp/tpl/clients /tmp/tpl/tests .
cp /tmp/tpl/build.gradle.kts /tmp/tpl/settings.gradle.kts /tmp/tpl/gradle.properties .
cp -r /tmp/tpl/gradle /tmp/tpl/gradlew /tmp/tpl/gradlew.bat /tmp/tpl/.editorconfig .
rm -rf /tmp/tpl
```

`settings.gradle.kts` 의 `rootProject.name` 과 패키지 루트(`io.dodn.springboot`)를
프로젝트 이름에 맞게 바꾼다. 패키지 경로를 바꿨다면 스킬 문서의 예시 경로도 그에 맞춰 읽는다.

템플릿 루트의 `CLAUDE.md`·`AGENTS.md`·`README.md` 는 가져오지 않는다 — 저장소 루트의
것과 충돌한다.

## 2. 확인

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
| `:core:core-api:bootJar` | 배포 이미지 빌드 |

## 3. 커밋해서 올리기

**에이전트는 push 된 코드만 본다.** 로컬에서 만든 뼈대는 올리기 전까지 에이전트에게
존재하지 않는다 — 첫 구축을 지시하기 전에 반드시 올린다.

```bash
git add -A
git commit -m "chore:백엔드 뼈대 추가"
git push
```

커밋 메시지는 `<type>:<제목>` 형식(콜론 뒤 공백 없음)을 쓴다 — 에이전트도 같은 형식을 쓴다.

`api` 노드는 시작할 때 `backend/settings.gradle.kts` 가 있는지 확인하고, 없으면 구조를
지어내지 않고 보고 후 중단한다.

## 4. 실행

```bash
./gradlew :core:core-api:bootRun
```

기본 포트는 8080 이다. 프론트엔드는 `frontend/.env` 로 이 주소를 가리킨다 — 서로 읽지 않는다.

## 5. 새 도메인을 추가할 때

파일을 어디에 두는지는 `.claude/skills/kotlin-module-layout/SKILL.md` 의 배치표를 본다.
만드는 순서는 위에서 아래로:

    core-enum → 엔티티 → 리포지토리 → 도메인 모델 → 구현 레이어 → 도메인 서비스 → DTO → 컨트롤러

템플릿의 `Example*` 파일들이 각 레이어의 표준 형태다. 첫 도메인을 만든 뒤 지워도 된다.

## 6. 응답 형식

응답은 항상 `ApiResponse<T>` 로 감싼다. 새 엔드포인트를 만들면 저장소 루트
[CONTRACT.md](../CONTRACT.md) 에 계약을 기록한다 — 프론트가 그 문서를 보고 화면을 만든다.

## 배포 전에

- 이미지는 [Dockerfile](Dockerfile) 로 빌드한다. `bootJar` 산출물을 담기만 하므로
  `./gradlew :core:core-api:bootJar` 를 먼저 실행해야 한다 (CI 가 알아서 한다).

- DB 접속 정보처럼 환경마다 달라지는 값은 배포 환경변수로 준다.
