---
name: kotlin-test
description: 유닛 테스트 작성과 리뷰 규칙. 테스트 메서드 하나가 기능 하나만 검증하도록 쪼개는 법, MockK 스텁 범위, 레이어별 테스트 대상, unitTest 태스크를 다룰 때 사용한다. 요구사항을 구현할 때는 항상 함께 사용해 테스트를 같이 작성한다. "테스트 추가", "테스트 짜줘", "커버리지" 요청에도 사용할 것.
---

# 유닛 테스트

**자리:** 대상과 같은 패키지의 `src/test/kotlin/...`, 파일명은 `<대상>Test.kt` **실행:** `./gradlew unitTest` — 태그가 없는 테스트만 돈다. DB·스프링 컨텍스트가 필요 없어야 한다.

## 요구사항이 오면 테스트도 함께 온다

새 동작(분기·정책·검증·상태 변경)을 만들면 **같은 변경에 유닛 테스트를 포함한다.** "나중에 테스트 추가"는 없다. 테스트가 없는 새 동작은 미완성이다.

## 한 메서드 = 한 기능

테스트 메서드 하나는 **검증 대상 행위 하나**만 확인한다. 시나리오가 둘이면 메서드도 둘이다.

```kotlin
class TodoAppenderTest {
    private val todoRepository: TodoRepository = mockk()
    private val appender = TodoAppender(todoRepository)

    @Test
    fun `제목이 있으면 저장한다`() {
        every { todoRepository.save(any()) } returns todoEntity(title = "장보기")

        val result: TodoResult = appender.append(memberId = 1L, command = TodoCreateCommand("장보기"))

        assertThat(result.title).isEqualTo("장보기")
    }

    @Test
    fun `제목이 공백이면 예외를 던진다`() {
        assertThatThrownBy { appender.append(memberId = 1L, command = TodoCreateCommand("  ")) }
            .isInstanceOf(ApiException 하위 예외 —:class.java)
    }
}
```

```kotlin
// ❌ 한 메서드에 여러 기능 — 앞에서 실패하면 뒤는 확인조차 안 된다
@Test
fun `todo 생성 테스트`() {
    val created = appender.append(1L, TodoCreateCommand("장보기"))
    assertThat(created.title).isEqualTo("장보기")

    val toggled = updater.toggle(created.id)          // 다른 기능
    assertThat(toggled.done).isTrue()

    assertThatThrownBy { appender.append(1L, TodoCreateCommand("")) }  // 또 다른 기능
}
```

## 쪼개는 기준

- 검증 대상 메서드가 다르면 → 나눈다.

- 같은 메서드라도 **조건이 다르면** 나눈다: 성공 / 값이 없음 / 권한 없음 / 한도 초과.

- 단언은 **하나의 결론**만 확인한다. 한 결과 객체의 관련 필드 몇 개를 함께 보는 것은 하나로 친다.

- 준비(given) 때문에 다른 기능을 호출하는 것은 괜찮다. 그 호출 결과를 **단언하지 않으면** 된다.

- `when`/`then` 이 한 메서드에 두 번 반복되면 쪼개라는 신호다.

## 이름과 형식

- 이름은 백틱 한글로 **조건과 기대 결과**를 적는다: `` `제목이 공백이면 예외를 던진다` ``.

- `테스트`, `성공`, `케이스1` 같은 이름은 쓰지 않는다.

- 본문은 given → when → then 순서로 쓰고 빈 줄로 나눈다. 주석으로 `// given` 을 달지 않는다(구조로 보인다).

- 단언은 AssertJ(`assertThat`, `assertThatThrownBy`)로 통일한다.

## 무엇을 테스트하나

| 대상 | 테스트할 것 | 협력 객체 |
|---|---|---|
| 도메인 서비스 | 유스케이스 흐름, 조건 분기, 예외 | 구현 레이어를 `mockk()` |
| 구현 레이어 | 조회·저장 결과 변환, 없음 처리 | 리포지토리를 `mockk()` |
| 엔티티 | 상태 변경 규칙과 불변식 | 목 없이 직접 생성 |
| 요청 DTO | 변환 메서드, 검증이 필요한 값 다듬기 | 없음 |

- 컨트롤러·리포지토리·외부 연동은 유닛 테스트 대상이 아니다. 각각 RestDocs 테스트(`restdocs` 태그)와 통합 테스트(`context` 태그)로 다룬다.

- 스프링 컨텍스트(`@SpringBootTest`)를 유닛 테스트에 띄우지 않는다. 느리고 `unitTest` 에서 제외된다.

## MockK 사용 범위

- **쓰는 값만 스텁한다.** 테스트가 보지 않는 호출까지 `every` 로 채우지 않는다.

- 반환값 검증으로 충분하면 `verify` 를 쓰지 않는다. 호출 횟수가 그 자체로 요구사항일 때만 쓴다.

- 테스트 대상은 목으로 만들지 않는다. 목이 대상을 대신하면 아무것도 검증하지 않는 테스트가 된다.

- 반복되는 픽스처는 파일 하단의 작은 팩토리 함수로 만든다(`private fun todoEntity(...)`). 프레임워크를 도입하지 않는다.

## 완료 전 검증 — 네 가지를 하고 숫자를 남긴다

`BUILD SUCCESSFUL` 은 증명이 아니다. 보고에는 형용사 대신 숫자를 쓴다.

**(1) 테스트 실계수를 센다.** Gradle 은 캐시로 태스크를 건너뛰고도 성공이라 말한다.

```bash
python3 -c "
import pathlib,re
tot=0
for d in pathlib.Path('.').rglob('build/test-results/test'):
    tot+=sum(int(re.search(r'tests=\"(\d+)\"', f.read_text()[:400]).group(1)) for f in d.glob('*.xml'))
print(tot)"
```
리팩토링이면 이전 계수와 같아야 한다.

**(2) 변이로 이빨을 본다.** 바꾼 규칙마다 그것을 무력화하고 테스트가 깨지는지 본다.
조건을 `true` 로, 상수를 다른 값으로 바꿔 돌린다. **합격 기준은 1건 이상 실패.**
0이면 그 규칙에는 테스트가 없다 — 고치기 전에 테스트를 먼저 쓴다.

**(3) 다른 포트로 실제 띄운다.** 상시 dev 서버를 죽이지 않는다.
기동에 무엇이 필요한지는 프로젝트마다 다르니 한 번 알아내 CLAUDE.md 에 적어 둔다.

**(4) 와이어 계약을 실호출로 대조한다.** 응답 필드명·enum 값을 건드렸으면 반드시 눈으로 본다.

보고에는 **하지 못한 검증**도 적는다. 빠뜨린 것을 적지 않으면 다음 사람이 속는다.

## 적발 신호

| 신호 | 문제 | 심각도 |
|---|---|---|
| 새 분기·정책·검증에 테스트 없음 | 미검증 동작 유입 | Critical |
| 한 메서드가 여러 기능·시나리오를 검증 | 실패 지점 은폐 | Critical |
| 테스트 대상을 목으로 대체 | 아무것도 검증하지 않음 | Critical |
| 단언 없는 테스트 | 통과만 하는 껍데기 | Critical |
| 실패를 통과시키려 단언 약화·테스트 삭제 | 검증 무력화 | Critical |
| 유닛 테스트에 `@SpringBootTest` | 느림·unitTest 제외 | Important |
| 쓰지 않는 호출까지 스텁 | 결합·잡음 | Important |
| `테스트1`·`성공` 같은 이름 | 실패 시 원인 불명 | Important |
| 반환값으로 충분한데 `verify` 남발 | 구현 결합 | Important |

## 체크리스트

- [ ] 이번 변경의 새 동작마다 테스트가 있는가

- [ ] 테스트 메서드 하나가 기능 하나만 확인하는가

- [ ] 이름이 조건과 기대 결과를 말하는가

- [ ] 성공 1 + 실패(조건별) 가 각각 별도 메서드인가

- [ ] `./gradlew ktlintCheck unitTest` 가 통과하는가
